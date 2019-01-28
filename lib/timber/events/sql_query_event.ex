defmodule Timber.Events.SQLQueryEvent do
  @moduledoc """
  The `SQLQueryEvent` tracks *outgoing* SQL queries.

  This gives you structured insight into SQL query performance within your application.

  The defined structure of this data can be found in the log event JSON schema:
  https://github.com/timberio/log-event-json-schema

  Timber can automatically track SQL query events if you use `Ecto` and setup
  `Timber.Ecto`.
  """

  @type t :: %__MODULE__{
          sql: String.t(),
          time_ms: integer
        }

  @enforce_keys [:sql, :time_ms]
  defstruct [:sql, :time_ms]

  @doc """
  Message to be used when logging.
  """
  @spec message(t) :: IO.chardata()
  def message(%__MODULE__{sql: sql, time_ms: time_ms}),
    do: ["Processed ", sql, " in ", to_string(time_ms), "ms"]
end
