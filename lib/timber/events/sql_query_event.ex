defmodule Timber.Events.SQLQueryEvent do
  @moduledoc """
  The `SQLQueryEvent` tracks *outgoing* SQL queries. This gives you structured insight into
  SQL query performance within your application.

  Timber can automatically track SQL query events if you use `Ecto` and setup
  `Timber.Integrations.EctoLogger`.
  """

  @type t :: %__MODULE__{
    sql: String.t,
    time_ms: float
  }

  @enforce_keys [:sql, :time_ms]
  defstruct [:sql, :time_ms]

  @doc """
  Message to be used when logging.
  """
  @spec message(t) :: IO.chardata
  def message(%__MODULE__{sql: sql, time_ms: time_ms}),
    do: ["Processed ", sql, " in ", to_string(time_ms), "ms"]
end
