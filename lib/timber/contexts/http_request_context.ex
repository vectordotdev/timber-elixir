defmodule Timber.Contexts.HTTPRequestContext do
  @moduledoc """
  The HTTP request context tracks incoming HTTP requests

  To manually add an HTTP request to the stack, you should use the
  `Timber.add_http_request_context/7` function. However, Timber can
  automatically add them to the stack if you use a `Plug` based
  framework through the `Timber.Plug`.
  """

  @type t :: %__MODULE__{
    host: String.t,
    headers: [header],
    method: method,
    path: String.t,
    port: pos_integer,
    scheme: String.t,
    query_params: %{String.t => String.t},
  }

  @type method :: :connect | :delete | :get | :head | :options | :post | :put | :trace

  @type header :: {String.t, String.t}

  @type response :: %{
    bytes: non_neg_integer,
    headers: [header],
    status: pos_integer
  }

  defstruct [:host, :headers, :method, :path, :port, :scheme, :query_params]
end
