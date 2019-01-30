defmodule Timber.Events.SQLQueryEvent do
  @deprecated_message ~S"""
  The `Timber.Events.SQLQueryEvent` module is deprecated.

  The next evolution of Timber (2.0) no long requires a strict schema and therefore
  simplifies how users log events.

  To easily migrate, please install the `:timber_ecto` library:

  https://github.com/timberio/timber-elixir-ecto
  """

  @moduledoc ~S"""
  **DEPRECATED**

  #{@deprecated_message}
  """

  @type t :: %__MODULE__{
          sql: String.t(),
          time_ms: integer
        }

  @enforce_keys [:sql, :time_ms]
  defstruct [:sql, :time_ms]

  @doc false
  @deprecated @deprecated_message
  @spec message(t) :: IO.chardata()
  def message(%__MODULE__{sql: sql, time_ms: time_ms}),
    do: ["Processed ", sql, " in ", to_string(time_ms), "ms"]

  defimpl Timber.Eventable do
    def to_event(event) do
      event = Map.from_struct(event)
      %{sql_query_executed: event}
    end
  end
end
