defmodule Timber.Contexts.HTTPResponseContext do
  @moduledoc """
  The HTTP response context tracks outgoing HTTP responses.

  Timber can automatically add responses to the context stack if you
  use a `Plug` based framework through `Timber.Plug`.
  """

  @type t :: %__MODULE__{
    bytes: non_neg_integer,
    headers: [header],
    status: pos_integer
  }

  @type header :: {String.t, String.t}

  defstruct [:bytes, :headers, :status]
end
