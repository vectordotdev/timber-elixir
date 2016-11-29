defmodule Timber.Contexts.OrganizationContext do
  @moduledoc """
  The organization context tracks the organization of the currently
  authenticated user

  You will want to add this context at the time you determine
  the organization a user belongs to, typically in the authentication
  flow.
  """

  @type t :: %__MODULE__{
    id: String.t,
    name: String.t
  }

  @type m :: %{
    id: String.t,
    name: String.t
  }

  defstruct [:id, :name]
end
