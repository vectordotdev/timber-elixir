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

    context = Keyword.get(metdata, :timber_context, %{})
    event = case Keyword.get(metadata, :timber_event, nil) do
      nil -> nil
      data -> Event.to_event(data)
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
    # Convert to a map for encoding.
    map = Map.from_struct(log_entry)

    # Key the event in a form that the Timber API expects.
    map = Map.get(map, :event, nil) do
      nil -> map
      event ->
        event_map =
          event
          |> Map.from_struct()
          |> Util.drop_nil_values()
        keyed_event = %{event_key(event) => event_map}
        Map.put(map, :event, keyed_event)
    end

    only = Keyword.get(options, :only, false)

    value_to_encode =
      if only do
        Map.take(map, only)
      else
        map
      end
      |> Utils.drop_nil_values()

    encode!(format, value_to_encode)
  end

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
