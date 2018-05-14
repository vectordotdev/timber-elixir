defmodule Timber.LogEntry do
  @moduledoc """
  The LogEntry module formalizes the structure of every log entry
  as defined by Timber's log event JSON schema: https://github.com/timberio/log-event-json-schema.
  The ensures log lines adhere to a normalized and consistent structure
  providing for predictability and reliability for downstream consumers
  of this log data.
  """

  alias Timber.Config
  alias Timber.Context
  alias Timber.Contexts.RuntimeContext
  alias Timber.Contexts.SystemContext
  alias Timber.GlobalContext
  alias Timber.LocalContext
  alias Timber.Event
  alias Timber.Eventable
  alias Timber.Utils.JSON
  alias Timber.Utils.Module, as: UtilsModule
  alias Timber.Utils.Timestamp, as: UtilsTimestamp
  alias Timber.Utils.Map, as: UtilsMap
  alias Timber.LogfmtEncoder
  alias Timber.LoggerBackends.HTTP, as: LoggerBackend

  defstruct [:dt, :level, :message, :meta, :event, :tags, :time_ms, context: %{}]

  @type t :: %__MODULE__{
    dt: String.t,
    level: Logger.level,
    message: iodata,
    context: Context.t,
    event: nil | Event.t,
    meta: nil | map,
    tags: nil | [String.t],
    time_ms: nil | float
  }

  @type m :: %__MODULE__{
    dt: String.t,
    level: Logger.level,
    message: binary,
    context: Context.t,
    event: nil | Event.t,
    meta: nil | map,
    tags: nil | [String.t],
    time_ms: nil | float
  }

  @type format :: :json | :logfmt | :msgpack

  @schema "https://raw.githubusercontent.com/timberio/log-event-json-schema/v3.1.1/schema.json"

  @doc """
  Creates a new `LogEntry` struct

  This function will merge the global context from `Timber.GlobalContext`
  with any context present in the `:timber_metadata` key in the
  metadata parameter.
  """
  @spec new(LoggerBackend.timestamp, Logger.level, Logger.message, Keyword.t) :: t
  def new(timestamp, level, message, metadata) do
    dt_iso8601 =
      if Config.use_nanosecond_timestamps? do
        DateTime.utc_now()
        |> DateTime.to_iso8601()
      else
        timestamp
        |> UtilsTimestamp.format_timestamp()
        |> IO.chardata_to_string()
      end

    global_context = GlobalContext.get()

    metadata_context = LocalContext.extract_from_metadata(metadata)

    context =
      global_context
      |> Context.merge(metadata_context)
      |> add_runtime_context(metadata)
      |> add_system_context()

    meta = Keyword.get(metadata, :meta)
    {message, event} = extract_message_and_event(metadata, message)
    tags = Keyword.get(metadata, :tags)
    time_ms = Keyword.get(metadata, :time_ms)

    %__MODULE__{
      dt: dt_iso8601,
      level: level,
      message: message,
      context: context,
      event: event,
      meta: meta,
      tags: tags,
      time_ms: time_ms
    }
  end

  # Add the default Elixir Logger runtime metadata as runtime context.
  defp add_runtime_context(context, metadata) do
    application = Keyword.get(metadata, :application)
    module_name = Keyword.get(metadata, :module)
    module_name =
      if module_name do
        UtilsModule.name(module_name)
      else
        module_name
      end

    fun = Keyword.get(metadata, :function)
    file = Keyword.get(metadata, :file)
    line = Keyword.get(metadata, :line)
    vm_pid =
      Keyword.get(metadata, :pid, self())
      |> :erlang.pid_to_list()
      |> :erlang.iolist_to_binary()
    runtime_context =
      %RuntimeContext{
        application: application,
        module_name: module_name,
        function: fun,
        file: file,
        line: line,
        vm_pid: vm_pid
      }

    Context.add(context, runtime_context)
  end

  defp add_system_context(context) do
    {:ok, hostname} =:inet.gethostname()
    hostname = to_string(hostname)

    pid =
      case Integer.parse(System.get_pid()) do
        {pid, _units} -> pid
        _ -> nil
      end

    system_context = %SystemContext{hostname: hostname, pid: pid}
    Context.add(context, system_context)
  end

  # Attemps to extract the message and event from the given logger metadata and message.
  # We take the message so that we can convert upstream error logger messages into actual
  # `ErrorEvent.t` events.
  defp extract_message_and_event(metadata, message) do
    case Event.extract_from_metadata(metadata) do
      nil ->
        if Keyword.has_key?(metadata, :error_logger) do
          case Timber.Events.ErrorEvent.from_log_message(to_string(message)) do
            {:ok, event} ->
              message = Timber.Events.ErrorEvent.message(event)
              {message, event}

            {:error, _reason} ->
              {message, nil}
          end
        else
          {message, nil}
        end

      data ->
        event = Eventable.to_event(data)
        {message, event}
    end
  end

  def schema, do: @schema

  @doc """
  Encodes the log event to chardata

  ## Options

  - `:except` - A list of key names. All key names except the ones passed will be encoded.
  - `:only` - A list of key names. Only the key names passed will be encoded.
  """
  @spec encode_to_iodata!(t, format, Keyword.t) :: iodata
  def encode_to_iodata!(log_entry, format, options \\ []) do
    log_entry
    |> to_map!(options)
    |> encode_map_to_iodata!(format)
  end

  @spec to_map!(t, Keyword.t) :: m
  def to_map!(log_entry, options \\ []) do
    only = Keyword.get(options, :only)
    except = Keyword.get(options, :except)

    log_entry
    |> Map.from_struct()
    |> map_take(only)
    |> map_drop(except)
    |> Map.update(:message, nil, &IO.chardata_to_string/1)
    |> Map.update(:event, nil, fn existing_event ->
      if existing_event != nil do
        Event.to_api_map(existing_event)
      else
        existing_event
      end
    end)
    |> Map.put(:"$schema", @schema)
    |> UtilsMap.recursively_drop_blanks()
  end

  defp map_take(map, nil), do: map
  defp map_take(map, keys), do: Map.take(map, keys)

  defp map_drop(map, nil), do: map
  defp map_drop(map, keys), do: Map.drop(map, keys)

  @spec encode_map_to_iodata!(map, format) :: iodata
  defp encode_map_to_iodata!(map, :json) do
    JSON.encode_to_iodata!(map)
  end

  # The logfmt encoding will actually use a pretty-print style
  # of encoding rather than converting the data structure directly to
  # logfmt
  defp encode_map_to_iodata!(map, :logfmt) do
    context =
      case Map.get(map, :context) do
        nil -> []
        val -> [?\n, ?\t, "Context: ", LogfmtEncoder.encode!(val)]
      end

    event =
      case Map.get(map, :event) do
        nil -> []
        val -> [?\n, ?\t, "Event: ", LogfmtEncoder.encode!(val)]
      end

    meta =
      case Map.get(map, :meta) do
        nil -> []
        val -> [?\n, ?\t, "Meta: ", LogfmtEncoder.encode!(val)]
      end

    [context, event, meta]
  end
end
