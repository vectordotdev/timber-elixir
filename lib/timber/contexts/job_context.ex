defmodule Timber.Contexts.JobContext do
  @moduledoc ~S"""
  **DEPRECATED**

  This module is deprecated in favor of using `map`s. The next evolution of Timber (2.0)
  no long requires a strict schema and therefore simplifies how users set context:

      Timber.add_context(job: %{id: "abcd1234"})

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

  defimpl Timber.Contextable do
    def to_context(context) do
      context = Map.from_struct(context)
      %{job: context}
    end
  end
end
