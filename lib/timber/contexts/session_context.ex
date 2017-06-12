defmodule Timber.Contexts.SessionContext do
  @moduledoc """
  The Session context tracks the current session. It it's a way to track users without the
  need for authentication.

  Note: Timber can automatically add context information about HTTP requests if
  you use a `Plug` based framework through the `Timber.Integrations.ContextPlug`.
  """

  @type t :: %__MODULE__{
    id: String.t
  }

  @type m :: %{
    id: String.t
  }

  defstruct [:id]
end
