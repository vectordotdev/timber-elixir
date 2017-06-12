defmodule Timber.Contexts.UserContext do
  @moduledoc """
  The User context tracks the currently authenticated user and allows you to
  tail indibidual user in the Timber console.

  You will want to add this context at the time you authenticate the user:

  ```elixir
  %Timber.Contexts.UserContext{id: "my_user_id", name: "John Doe", email: "john@doe.com"}
  |> Timber.add_context()
  ```
  """

  @type t :: %__MODULE__{
    id: String.t,
    name: String.t,
    email: String.t
  }

  @type m :: %{
    id: String.t,
    name: String.t,
    email: String.t
  }

  defstruct [:id, :name, :email]
end
