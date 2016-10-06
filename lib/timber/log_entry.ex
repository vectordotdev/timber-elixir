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
  it was logged at, and a context stack that represents the context of
  this process. The context stack acts like a chronological record.
  See the main `Timber` module for more information.
  """

  alias Timber.ContextEntry
  alias Timber.Logger

  @type context_stack :: [ContextEntry.t] | []

  @type t :: %__MODULE__{
    dt: IO.chardata,
    level: Logger.level,
    message: Logger.message,
    context: context_stack
  }

  defstruct context: [], dt: nil, level: nil, message: nil

  @doc """
  Creates a new `LogEntry` struct

  The metadata from Logger is given as the final parameter. If the
  `:timber_context` key is present in the metadata, it will be used
  to fill the context for the log entry. Otherwise, a blank context
  will be used.
  """
  @spec new(Logger.timestamp, Logger.level, Logger.message, Keyword.t) :: t
  def new(timestamp, level, message, metadata) do
    io_timestamp = Timber.Utils.format_timestamp(timestamp)

    context = Keyword.get(metadata, :timber_context, [])

    %__MODULE__{
      dt: io_timestamp,
      level: level,
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
    # Reformats the context stack so that the contexts
    # can be properly interpreted by the system
    context = Enum.map(log_entry.context, &ContextEntry.context_for_encoding/1)
    log_entry = Map.put(log_entry, :context, context)

    only = Keyword.get(options, :only, false)

    value_to_encode =
      if only do
        Map.take(log_entry, only)
      else
        log_entry
      end

    Poison.encode_to_iodata!(value_to_encode)
  end
end
