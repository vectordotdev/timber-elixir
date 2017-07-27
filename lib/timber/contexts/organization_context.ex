defmodule Timber.Contexts.OrganizationContext do
  @moduledoc """
  The organization context tracks the organization of the currently
  authenticated user.

  You will want to add this context at the time you determine
  the organization a user belongs to, typically in the authentication
  flow.

  ```elixir
  %Timber.Contexts.OrganizationContext{id: "my_organization_id", name: "Lumberjacks Doe"}
  |> Timber.add_context()
  ```
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
