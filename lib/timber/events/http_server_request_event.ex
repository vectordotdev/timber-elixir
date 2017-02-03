defmodule Timber.Events.HTTPServerRequestEvent do
  @moduledoc """
  The `HTTPServerRequestEvent` tracks *incoming* HTTP requests. This gives you structured
  insight into the HTTP requests coming into your app.

  Timber can automatically track incoming HTTP requests if you use a `Plug` based framework.
  See `Timber.Integrations.ContextPlug` and `Timber.Integerations.EventPlug`. Also, the
  `README.md` outlines how to set these up.
  """

  alias Timber.Utils

  @type t :: %__MODULE__{
    host: String.t,
    headers: headers | nil,
    method: String.t,
    path: String.t,
    port: pos_integer | nil,
    query_string: String.t | nil,
    scheme: String.t
  }

  @type headers :: %{
    content_type: String.t | nil,
    remote_addr: String.t | nil,
    referrer: String.t | nil,
    request_id: String.t | nil,
    user_agent: String.t | nil
  }

  @enforce_keys [:host, :method, :path, :scheme]
  defstruct [:host, :headers, :method, :path, :port, :query_string, :scheme]

  @recognized_headers ~w(
    content-type
    remote-addr
    referrer
    user-agent
    x-request-id
  )

  @doc """
  Builds a new struct taking care to normalize data into a valid state. This should
  be used, where possible, instead of creating the struct directly.
  """
  @spec new(Keyword.t) :: t
  def new(opts) do
    opts =
      opts
      |> Keyword.update(:headers, nil, fn headers -> Utils.normalize_headers(headers, @recognized_headers) end)
      |> Keyword.update(:method, nil, &Utils.normalize_method/1)
      |> Keyword.merge(Utils.normalize_url(Keyword.get(opts, :url)))
      |> Keyword.delete(:url)
      |> Enum.filter(fn {_k,v} -> v != nil end)
    struct!(__MODULE__, opts)
  end

  @doc """
  Message to be used when logging.
  """
  @spec message(t) :: IO.chardata
  def message(%__MODULE__{method: method, path: path}),
    do: [method, " ", path]
end
