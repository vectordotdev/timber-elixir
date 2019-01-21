defmodule Timber.Contexts.UserContext do
  @moduledoc ~S"""
  **DEPRECATED**

  This module is deprecated in favor of using `map`s. The next evolution of Timber (2.0)
  no long requires a strict schema and therefore simplifies how users set context:

      Timber.add_context(user: %{id: "abcd1234"})

  """

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          email: String.t()
        }

  @type m :: %{
          id: String.t(),
          name: String.t(),
          email: String.t()
        }

  defstruct [:id, :name, :email]

  defimpl Timber.Contextable do
    def to_context(context) do
      context = Map.from_struct(context)
      %{user: context}
    end
  end
end
