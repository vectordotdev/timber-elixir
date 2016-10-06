defmodule Timber.Contexts.HTTPResponseContext do
  @moduledoc """
  The HTTP response context tracks outgoing HTTP responses.

  To manually add an HTTP response to the stack, you should use the
  `Timber.add_http_response_context/3` function. However, Timber can
  automatically add them to the stack if you use a `Plug` based framework
  through the `Timber.Plug`.
  """

  @type t :: %__MODULE__{
    bytes: non_neg_integer,
    headers: [header],
    status: pos_integer
  }

  @type header :: {String.t, String.t}

  defstruct [:bytes, :headers, :status]
end
