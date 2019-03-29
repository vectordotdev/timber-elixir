defmodule Timber.LogEntry do
  @moduledoc false
  # The LogEntry module formalizes the structure of every log entry as defined
  # by Timber's log event JSON schema:
  # https://github.com/timberio/log-event-json-schema. The ensures log lines
  # adhere to a normalized and consistent structure providing for predictability
  # and reliability for downstream consumers of this log data.

  alias Timber.Config
  alias Timber.Context
  alias Timber.Contexts.RuntimeContext
  alias Timber.Contexts.SystemContext
  alias Timber.GlobalContext
  alias Timber.JSON
  alias Timber.LocalContext
  alias Timber.Event
  alias Timber.Utils.Module, as: UtilsModule
  alias Timber.Utils.Timestamp, as: UtilsTimestamp
  alias Timber.LoggerBackends.HTTP, as: LoggerBackend

  defstruct [:dt, :level, :message, :event, context: %{}]

  #
  # Typespecs
  #

  @type t :: %__MODULE__{
          dt: String.t(),
          level: Logger.level(),
          message: iodata,
          context: Context.t(),
          event: nil | Event.t()
        }

  @type m :: %__MODULE__{
          dt: String.t(),
          level: Logger.level(),
          message: binary,
          context: Context.t(),
          event: nil | Event.t()
        }

  @type format :: :json | :msgpack

  #
  # API
  #

  @doc """
  Creates a new `LogEntry` struct

  This function will merge the global context from `Timber.GlobalContext`
  with any context present in the `:timber_metadata` key in the
  metadata parameter.
  """
  @spec new(LoggerBackend.timestamp(), Logger.level(), Logger.message(), Keyword.t()) :: t
  def new(timestamp, level, message, metadata \\ []) do
    dt_iso8601 =
      if Config.use_nanosecond_timestamps?() do
        DateTime.utc_now()
        |> DateTime.to_iso8601()
      else
        timestamp
        |> UtilsTimestamp.format_timestamp()
        |> IO.chardata_to_string()
      end

    global_context = GlobalContext.get()
    local_context = LocalContext.extract_from_metadata(metadata)
    inline_context = Keyword.get(metadata, :context)

    context =
      global_context
      |> Context.merge(local_context)
      |> Context.merge(inline_context)
      |> add_runtime_context(metadata)
      |> add_system_context()

    event =
      metadata
      |> Keyword.get(:event)
      |> try_to_event()

    %__MODULE__{
      dt: dt_iso8601,
      level: level,
      message: message,
      context: context,
      event: event
    }
  end

  #
  # Util
  #

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
    vm_pid = vm_pid_from_metadata(metadata)

    runtime_context = %RuntimeContext{
      application: application,
      module_name: module_name,
      function: fun,
      file: file,
      line: line,
      vm_pid: vm_pid
    }

    Context.merge(context, runtime_context)
  end

  defp add_system_context(context) do
    pid =
      case Integer.parse(System.get_pid()) do
        {pid, _units} -> pid
        _ -> nil
      end

    system_context = %SystemContext{hostname: Timber.Cache.hostname(), pid: pid}
    Context.merge(context, system_context)
  end

  @doc """
  Encodes the log event to `binary`

  ## Options

  - `:except` - A list of key names. All key names except the ones passed will be encoded.
  - `:only` - A list of key names. Only the key names passed will be encoded.
  """
  @spec encode_to_binary!(t, format, Keyword.t()) :: iodata
  def encode_to_binary!(log_entry, format, options \\ []) do
    log_entry
    |> to_map!(options)
    |> encode_map_to_binary!(format)
  end

  @doc """
  Encodes the log event to `iodata`

  ## Options

  - `:except` - A list of key names. All key names except the ones passed will be encoded.
  - `:only` - A list of key names. Only the key names passed will be encoded.
  """
  @spec encode_to_iodata!(t, format, Keyword.t()) :: iodata
  def encode_to_iodata!(log_entry, format, options \\ []) do
    log_entry
    |> to_map!(options)
    |> encode_map_to_iodata!(format)
  end

  @spec to_map!(t, Keyword.t()) :: m
  def to_map!(log_entry, options \\ []) do
    only = Keyword.get(options, :only)
    except = Keyword.get(options, :except)

    log_entry
    |> Map.from_struct()
    |> try_map_take(only)
    |> try_map_drop(except)
    |> try_move_to_root(:event)
    |> Map.update(:message, nil, &IO.chardata_to_string/1)
  end

  defp try_map_take(map, nil),
    do: map

  defp try_map_take(map, keys),
    do: Map.take(map, keys)

  defp try_map_drop(map, nil),
    do: map

  defp try_map_drop(map, keys),
    do: Map.drop(map, keys)

  defp try_move_to_root(map, key) do
    case Map.get(map, key) do
      val when is_map(val) ->
        map
        |> Map.delete(key)
        |> Map.merge(val)

      _else ->
        map
    end
  end

  defp try_to_event(nil),
    do: nil

  defp try_to_event(event) do
    Event.to_event(event)
  end

  @spec encode_map_to_binary!(map, format) :: iodata
  defp encode_map_to_binary!(map, :json) do
    JSON.encode_to_binary!(map)
  end

  @spec encode_map_to_iodata!(map, format) :: iodata
  defp encode_map_to_iodata!(map, :json) do
    JSON.encode_to_iodata!(map)
  end

  defp vm_pid_from_metadata(metadata) do
    vm_pid = Keyword.get(metadata, :pid, self())

    case vm_pid do
      vm_pid when is_pid(vm_pid) ->
        vm_pid
        |> :erlang.pid_to_list()
        |> :erlang.iolist_to_binary()

      vm_pid ->
        to_string(vm_pid)
    end
  end
end
