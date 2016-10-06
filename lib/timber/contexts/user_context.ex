defmodule Timber.Contexts.UserContext do
  @type t :: %__MODULE__{
    id: String.t,
    name: String.t,
    email: String.t
  }

  defstruct [:id, :name, :email]
end
