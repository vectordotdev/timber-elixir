defmodule Timber.LogEntry do
  @moduledoc """
  The LogEntry module formalizes the structure of every log entry

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
    event = Keyword.get(metadata, :timber_event, nil)

    %__MODULE__{
      dt: io_timestamp,
      level: level,
      event: event,
      message: message,
      context: context
    }
  end

  @doc """
  Encodes the log event to a JSON document

  ## Options
  
  - `:only` - A list of key names. Only the key names passed will be encoded.
  """
  @spec to_json_string!(t, Keyword.t) :: iodata | no_return
  def to_json_string!(log_entry, options) do
    # Reformats the event so that the event 
    # can be properly interpreted by the log ingester
    event = Event.event_for_encoding(log_entry.event)
    log_entry = %__MODULE__{log_entry | event: event}

    only = Keyword.get(options, :only, false)

    value_to_encode =
      if only do
        Map.take(log_entry, only)
      else
        Map.from_struct(log_entry)
      end
      |> Utils.drop_nil_values()

    Poison.encode_to_iodata!(value_to_encode)
  end
end
