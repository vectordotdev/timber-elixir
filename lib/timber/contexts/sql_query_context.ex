defmodule Timber.Contexts.SQLQueryContext do
  @moduledoc """
  The SQL Query context tracks SQL query performance
  """

  #TODO: Timber.Ecto.Logger

  @type t :: %__MODULE__{
    sql: String.t,
    time_ms: float,
    binds: %{String.t => String.t}
  }

  defstruct [:sql, :time_ms, :binds]
end
