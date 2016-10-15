defmodule Timber.Contexts.SQLQueryContext do
  @moduledoc """
  The SQL Query context tracks SQL query performance
  """

  @type t :: %__MODULE__{
    sql: String.t,
    time_ms: float
  }

  defstruct [:sql, :time_ms]
end
