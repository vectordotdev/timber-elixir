defmodule Timber.Contexts.JobContext do
  @moduledoc """
  The job context tracks the execution of background jobs or any isolated
  task with a reference. Add it like:

  ```elixir
  %Timber.Contexts.JobContext{id: "my_job_id"}
  |> Timber.add_context()
  ```
  """

  @type t :: %__MODULE__{
    id: String.t
  }

  @type m :: %{
    id: String.t
  }

  @enforce_keys [:id]
  defstruct [:id]
end
