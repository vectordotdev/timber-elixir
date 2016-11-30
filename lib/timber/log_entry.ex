defmodule Timber.LogEntry do
  @moduledoc """
  The LogEntry module formalizes the structure of every log entry.

  When a log is produced, it is converted to this intermediary form
  by the `Timber.Logger` module before being passed on to the desired
  transport. Each transport implements a `write/2` function as defined
  by the `Timber.Transport.write/2` behaviour. Inside of this function,
  the transport is responsible for formatting the data contained in a
  log entry appropriately.

  Each log entry consists of the log message, its level, the timestamp
  it was logged at, a context map, and an optional event.
  See the main `Timber` module for more information.
  """

  alias Timber.Context
  alias Timber.Logger
  alias Timber.Event
  alias Timber.Eventable
  alias Timber.Events
  alias Timber.Utils
  alias Timber.LogfmtEncoder

  @type format :: :json | :logfmt

  @type t :: %__MODULE__{
    dt: IO.chardata,
    level: Logger.level,
    message: Logger.message,
    context: Context.t,
    event: Event.t | nil
  }

  defstruct context: %{}, dt: nil, level: nil, message: nil, event: nil

  @doc """
  Creates a new `LogEntry` struct

  The metadata from Logger is given as the final parameter. If the
  `:timber_context` key is present in the metadata, it will be used
  to fill the context for the log entry. Otherwise, a blank context
  will be used.
  """
  @spec new(Logger.timestamp, Logger.level, Logger.message, Keyword.t) :: t
  def new(timestamp, level, message, metadata) do
    io_timestamp =
      Timber.Utils.format_timestamp(timestamp)
      |> IO.chardata_to_string()

    context = Keyword.get(metadata, :timber_context, %{})
    event = case Keyword.get(metadata, Timber.Config.event_key(), nil) do
      nil -> nil
      data -> Eventable.to_event(data)
    end

    %__MODULE__{
      dt: io_timestamp,
      level: level,
      event: event,
      message: message,
      context: context
    }
  end

  @doc """
  Encodes the log event to a string

  ## Options

  - `:only` - A list of key names. Only the key names passed will be encoded.
  """
  @spec to_string!(t, format, Keyword.t) :: IO.chardata
  def to_string!(log_entry, format, options) do
    map = to_map!(log_entry, options)
    encode!(format, map)
  end

  @spec to_map!(t, Keyword.t) :: map()
  defp to_map!(log_entry, options) do
    map =
      log_entry
      |> Map.from_struct()
      |> Map.update(:event, nil, fn existing_event ->
          to_api_map(existing_event)
         end)

    only = Keyword.get(options, :only, false)

    if only do
      Map.take(map, only)
    else
      map
    end
    |> Utils.drop_nil_values()
  end

  defp to_api_map(nil),
    do: %{}
  defp to_api_map(%Events.ControllerCallEvent{} = event),
    do: %{controller_call: Map.from_struct(event)}
  defp to_api_map(%Events.CustomEvent{type: type, data: data}),
    do: %{custom: %{type => data}}
  defp to_api_map(%Events.ExceptionEvent{} = event),
    do: %{exception: Map.from_struct(event)}
  defp to_api_map(%Events.HTTPRequestEvent{} = event),
    do: %{http_request: Map.from_struct(event)}
  defp to_api_map(%Events.HTTPResponseEvent{} = event),
    do: %{http_response: Map.from_struct(event)}
  defp to_api_map(%Events.SQLQueryEvent{} = event),
    do: %{sql_query: Map.from_struct(event)}
  defp to_api_map(%Events.TemplateRenderEvent{} = event),
    do: %{template_render: Map.from_struct(event)}

  @spec encode!(format, map) :: IO.chardata
  defp encode!(:json, value) do
    Poison.encode_to_iodata!(value)
  end

  # The logfmt encoding will actually use a pretty-print style
  # of encoding rather than converting the data structure directly to
  # logfmt
  defp encode!(:logfmt, value) do
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
