defmodule Timber.Contexts.HTTPRequestContext do
  @moduledoc """
  The HTTP request context tracks incoming HTTP requests

  Timber can automatically add incoming HTTP requests to the stack if
  you use a `Plug` based framework through the `Timber.Plug`.
  """

  @type t :: %__MODULE__{
    host: String.t,
    headers: [header],
    method: method,
    path: String.t,
    port: pos_integer,
    scheme: scheme,
    query_params: %{String.t => String.t},
  }

  @type method :: :connect | :delete | :get | :head | :options | :post | :put | :trace

  @type scheme :: :https | :http

  @type header :: {String.t, String.t}

  @type response :: %{
    bytes: non_neg_integer,
    headers: [header],
    status: pos_integer
  }

  defstruct [:host, :headers, :method, :path, :port, :scheme, :query_params]
end
