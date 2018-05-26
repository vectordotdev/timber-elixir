defmodule Timber.Contexts.JobContext do
  @moduledoc """
  The job context tracks the execution of background jobs or any isolated
  task with a reference. Add it like:

  ```elixir
  %Timber.Contexts.JobContext{attempt: 1, id: "my_job_id", queue_name: "my_job_queue"}
  |> Timber.add_context()
  ```
  """

  @type t :: %__MODULE__{
          attempt: nil | pos_integer,
          id: String.t(),
          queue_name: nil | String.t()
        }

  @type m :: %{
          attempt: nil | pos_integer,
          id: String.t(),
          queue_name: nil | String.t()
        }

  @enforce_keys [:id]
  defstruct [:attempt, :id, :queue_name]
end
