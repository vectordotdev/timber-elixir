defmodule Timber.Events.SQLQueryEvent do
  @moduledoc """
  The SQL Query event tracks SQL query performance.

  Timber can automatically track SQL query events if you
  use `Ecto` and setup `Timber.Ecto`.
  """

  @type t :: %__MODULE__{
    sql: String.t,
    time_ms: float
  }

  defstruct [:sql, :time_ms]

  def new(opts) do
    struct(__MODULE__, opts)
  end

  @spec message(t) :: IO.chardata
  def message(%__MODULE__{sql: sql, time_ms: time_ms}),
    do: "Processed #{sql} in #{time_ms}ms"
end
