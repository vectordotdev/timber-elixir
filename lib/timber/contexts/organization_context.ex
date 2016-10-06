defmodule Timber.Contexts.OrganizationContext do
  @moduledoc """
  The organization context tracks the organization of the currently
  authenticated user

  To add an organization contex to the stack, you should call
  `Timber.add_organization_context/2`.
  """

  @type t :: %__MODULE__{
    id: String.t,
    name: String.t
  }

  defstruct [:id, :name]
end
