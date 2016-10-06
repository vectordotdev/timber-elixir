defmodule Timber.Contexts.UserContext do
  @moduledoc """
  Tracks a user
  """

  @type t :: %__MODULE__{
    id: String.t,
    name: String.t,
    email: String.t
  }

  defstruct [:id, :name, :email]
end
