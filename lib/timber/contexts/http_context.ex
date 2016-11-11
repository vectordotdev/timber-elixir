defmodule Timber.Contexts.HTTPContext do
  @moduledoc """
  The HTTP context tracks information about an HTTP request currently
  being handled

  Timber can automatically add context information about HTTP requests if
  you use a `Plug` based framework through the `Timber.ContextPlug`.
  """

  @type t :: %__MODULE__{
    request_id: String.t | nil,
    remote_addr: String.t | nil
  }

  @type m :: %{
    optional(:request_id) => String.t,
    optional(:remote_addr) => String.t
  }

  defstruct [:request_id, :remote_addr]
end
