defmodule Timber.Contexts.HTTPContext do
  @moduledoc """
  The HTTP context tracks information about an HTTP request currently
  being handled.

  Note: Timber can automatically add context information about HTTP requests if
  you use a `Plug` based framework through the `Timber.Integrations.ContextPlug`.
  """

  @type t :: %__MODULE__{
    method: String.t,
    path: String.t,
    request_id: String.t | nil,
    remote_addr: String.t | nil
  }

  @type m :: %{
    :method => String.t,
    :path => String.t,
    optional(:request_id) => String.t,
    optional(:remote_addr) => String.t
  }

  defstruct [:method, :path, :request_id, :remote_addr]
end
