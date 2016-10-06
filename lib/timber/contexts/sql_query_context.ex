defmodule Timber.Contexts.SQLQueryContext do
  @type t :: %__MODULE__{
    sql: String.t,
    time_ms: float,
    binds: %{String.t => String.t}
  }

  defstruct [:sql, :time_ms, :binds]
end
