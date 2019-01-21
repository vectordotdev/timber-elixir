defmodule Timber.Contexts.OrganizationContext do
  @moduledoc ~S"""
  **DEPRECATED**

  This module is deprecated in favor of using `map`s. The next evolution of Timber (2.0)
  no long requires a strict schema and therefore simplifies how users set context:

      Timber.add_context(organization: %{id: "abcd1234"})

  """

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t()
        }

  @type m :: %{
          id: String.t(),
          name: String.t()
        }

  defstruct [:id, :name]

  defimpl Timber.Contextable do
    def to_context(context) do
      context = Map.from_struct(context)
      %{organization: context}
    end
  end
end
