defmodule Timber.Events.SQLQueryEvent do
  @moduledoc """
  The SQL Query event tracks SQL query performance
  """

  @type t :: %__MODULE__{
    description: String.t,
    sql: String.t,
    time_ms: float
  }

  defstruct [:description, :sql, :time_ms]

  def new(opts) do
    event = struct(__MODULE__, opts)
    description = "Processed #{event.sql} in #{event.time_ms} ms"
    %__MODULE__{ event | description: description }
  end
end
