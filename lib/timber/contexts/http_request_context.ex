defmodule Timber.Contexts.HTTPRequestContext do
  @moduledoc """
  The HTTP request context tracks incoming HTTP requests

  Timber can automatically add incoming HTTP requests to the stack if
  you use a `Plug` based framework through the `Timber.Plug`.
  """

  @type t :: %__MODULE__{
    request_id: String.t | nil
  }

  @type m :: %{
    optional(:request_id) => String.t
  }

  defstruct [:request_id]
end
