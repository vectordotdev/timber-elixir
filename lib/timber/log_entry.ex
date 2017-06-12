defmodule Timber.LogEntry do
  @moduledoc """
  The LogEntry module formalizes the structure of every log entry.

  When a log is produced, it is converted to this intermediary form
  by the `Timber.LoggerBackend` module before being passed on to the desired
  transport. Each transport implements a `write/2` function as defined
  by the `Timber.Transport.write/2` behaviour. Inside of this function,
  the transport is responsible for formatting the data contained in a
  log entry appropriately.

  Each log entry consists of the log message, its level, the timestamp
  it was logged at, a context map, and an optional event.
  See the main `Timber` module for more information.
  """

  alias Timber.Context
  alias Timber.Contexts.{RuntimeContext, SystemContext}
  alias Timber.LoggerBackend
  alias Timber.Event
  alias Timber.Eventable
  alias Timber.Utils.Logger, as: UtilsLogger
  alias Timber.Utils.Module, as: UtilsModule
  alias Timber.Utils.Timestamp, as: UtilsTimestamp
  alias Timber.Utils.Map, as: UtilsMap
  alias Timber.LogfmtEncoder

  defstruct context: %{}, dt: nil, level: nil, message: nil, event: nil, tags: nil, time_ms: nil

  @type format :: :json | :logfmt

  @type t :: %__MODULE__{
    dt: IO.chardata,
    level: LoggerBackend.level,
    message: LoggerBackend.message,
    context: Context.t,
    event: Event.t | nil,
    tags: nil | [String.t],
    time_ms: nil | float
  }

  @schema "https://raw.githubusercontent.com/timberio/log-event-json-schema/v2.1.0/schema.json"

  @doc """
  Creates a new `LogEntry` struct

  The metadata from Logger is given as the final parameter. If the
  `:timber_context` key is present in the metadata, it will be used
  to fill the context for the log entry. Otherwise, a blank context
  will be used.
  """
  @spec new(LoggerBackend.timestamp, Logger.level, Logger.message, Keyword.t) :: t
  def new(timestamp, level, message, metadata) do
    io_timestamp =
      timestamp
      |> UtilsTimestamp.format_timestamp()
      |> IO.chardata_to_string()

    context =
      metadata
      |> Keyword.get(:timber_context, %{})
      |> add_runtime_context(metadata)
      |> add_system_context()

    {message, event} = case UtilsLogger.get_event_from_metadata(metadata) do
      nil ->
        if Keyword.has_key?(metadata, :error_logger) do
          case Timber.Events.ExceptionEvent.new(to_string(message)) do
            {:ok, event} ->
              message = Timber.Events.ExceptionEvent.message(event)
              {message, event}

            {:error, _reason} -> {message, nil}
          end
        else
          {message, nil}
        end

      data -> {message, Eventable.to_event(data)}
    end

    %__MODULE__{
      dt: io_timestamp,
      level: level,
      event: event,
      message: message,
      context: context,
      tags: Keyword.get(metadata, :tags),
      time_ms: Keyword.get(metadata, :time_ms)
    }
  end

  # Add the default Elixir Logger runtime metadata as runtime context.
  defp add_runtime_context(context, metadata) do
    application = Keyword.get(metadata, :application)
    module_name = Keyword.get(metadata, :module)
    module_name = if module_name do
      UtilsModule.name(module_name)
    else
      module_name
    end
    fun = Keyword.get(metadata, :function)
    file = Keyword.get(metadata, :file)
    line = Keyword.get(metadata, :line)
    runtime_context = %RuntimeContext{application: application, module_name: module_name,
      function: fun, file: file, line: line}
    Context.add(context, runtime_context)
  end

  defp add_system_context(context) do
    hostname =
      case :inet.gethostname() do
        {:ok, hostname} -> to_string(hostname)
        _else -> nil
      end
    pid = System.get_pid()
    system_context = %SystemContext{hostname: hostname, pid: pid}
    Context.add(context, system_context)
  end

  def schema, do: @schema

  @doc """
  Encodes the log event to a string

  ## Options

  - `:only` - A list of key names. Only the key names passed will be encoded.
  """
  @spec to_string!(t, format, Keyword.t) :: IO.chardata
  def to_string!(log_entry, format, options \\ []) do
    log_entry
    |> to_map!(options)
    |> encode!(format)
  end

  @spec to_map!(t, Keyword.t) :: map()
  def to_map!(log_entry, options \\ []) do
    map =
      log_entry
      |> Map.from_struct()
      |> Map.update(:event, nil, fn existing_event ->
        if existing_event != nil do
          Event.to_api_map(existing_event)
        else
          existing_event
        end
      end)

    only = Keyword.get(options, :only, false)

    if only do
      Map.take(map, only)
    else
      map
    end
    |> Map.put(:"$schema", @schema)
    |> UtilsMap.recursively_drop_blanks()
  end

  @spec encode!(format, map) :: IO.chardata
  defp encode!(value, :json) do
    Timber.Config.json_encoder().(value)
  end

  # The logfmt encoding will actually use a pretty-print style
  # of encoding rather than converting the data structure directly to
  # logfmt
  defp encode!(value, :logfmt) do
    context =
      case Map.get(value, :context) do
        nil -> []
        val -> [?\n, ?\t, "Context: ", LogfmtEncoder.encode!(val)]
      end

    event =
      case Map.get(value, :event) do
        nil -> []
        val -> [?\n, ?\t, "Event: ", LogfmtEncoder.encode!(val)]
      end

    [context, event]
  end
end
