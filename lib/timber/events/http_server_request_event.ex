defmodule Timber.Events.HTTPServerRequestEvent do
  @moduledoc """
  The `HTTPServerRequestEvent` tracks *incoming* HTTP requests. This gives you structured
  insight into the HTTP requests coming into your app.

  Timber can automatically track incoming HTTP requests if you use a `Plug` based framework.
  See `Timber.Integrations.ContextPlug` and `Timber.Integerations.EventPlug`. Also, the
  `README.md` outlines how to set these up.
  """

  alias Timber.Utils.HTTPEvents, as: UtilsHTTPEvents

  @type t :: %__MODULE__{
    body: String.t | nil,
    host: String.t,
    headers: map | nil,
    method: String.t,
    path: String.t,
    port: pos_integer | nil,
    query_string: String.t | nil,
    request_id: String.t | nil,
    scheme: String.t
  }

  @enforce_keys [:host, :method, :scheme]
  defstruct [:body, :host, :headers, :method, :path, :port, :query_string, :request_id, :scheme]

  @doc """
  Builds a new struct taking care to:

  * Parsing the `:url` and mapping it to the appropriate attributes.
  * Normalize header values so they are consistent.
  * Normalize the method.
  * Removes "" or nil values.
  """
  @spec new(Keyword.t) :: t
  def new(opts) do
    opts =
      opts
      |> Keyword.delete(:body) # Don't store the body for now. We store the params in the ControllerCallEvent. We can re-enable this upon request.
      |> Keyword.update(:headers, nil, fn headers -> UtilsHTTPEvents.normalize_headers(headers) end)
      |> Keyword.update(:method, nil, &UtilsHTTPEvents.normalize_method/1)
      |> Keyword.merge(UtilsHTTPEvents.normalize_url(Keyword.get(opts, :url)))
      |> Keyword.delete(:url)
      |> Enum.filter(fn {_k,v} -> !(v in [nil, ""]) end)

    struct!(__MODULE__, opts)
  end

  @doc """
  Message to be used when logging.
  """
  @spec message(t) :: IO.chardata
  def message(%__MODULE__{method: method, path: path}),
    do: [method, " ", path]
end
