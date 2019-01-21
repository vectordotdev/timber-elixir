defmodule Timber.Events.SQLQueryEvent do
  @moduledoc ~S"""
  **DEPRECATED**

  This module is deprecated in favor of using `map`s. The next evolution of Timber (2.0)
  no long requires a strict schema and therefore simplifies how users set context:

      Logger.info(fn ->
        message = "Processed #{sql} in #{duration_ms}ms"
        event = %{sql_query_executed: %{sql: sql, duration_ms: duration_ms}}
        {message, event: event}
      end)

  Please note, you can use the official
  [`:timber_ecto`](https://github.com/timberio/timber-elixir-ecto) integration to
  automatically structure this event with metadata.
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

  defimpl Timber.Eventable do
    def to_event(event) do
      event = Map.from_struct(event)
      %{sql_query_executed: event}
    end
  end
end
