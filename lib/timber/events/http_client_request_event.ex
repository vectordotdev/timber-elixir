defmodule Timber.Events.HTTPClientRequestEvent do
  @moduledoc """
  The `HTTPClientRequestEvent` tracks *outgoing* HTTP requests giving you structured insight
  into communication with external services.

  This event is HTTP client agnostic, use it with your HTTP client of choice.

  ## Hackney Example

    iex> req_method = :get
    iex> req_url = "https://some.api.com/path?query=1"
    iex> req_headers = [{"Accept", "application/json"}]
    iex> req_event = Timber.Events.HTTPClientRequestEvent.new(method: req_method, url: req_url, headers: req_headers)
    iex> message = Timber.Events.HTTPClientRequestEvent.message(req_event)
    iex> Logger.info message, event: req_event
    iex> timer = Timber.Timer.start()
    iex> {:ok, status, headers, body} = :hackney.request(req_method, req_url, req_headers, "")
    iex> resp_event = Timber.Events.HTTPClientResponseEvent.new(bytes: 200, headers: headers, status: status, timer: timer)
    iex> message = Timber.Events.HTTPClientResponseEvent.message(resp_event)
    iex> Logger.info message, event: resp_event

  """

  alias Timber.Events.HTTPUtils

  @enforce_keys [:host, :method, :path, :scheme]
  defstruct [:headers, :host, :method, :path, :port, :query_string, :scheme, :service_name]

  @type t :: %__MODULE__{
    headers: headers | nil,
    host: String.t,
    method: String.t,
    path: String.t,
    port: pos_integer | nil,
    query_string: String.t | nil,
    scheme: String.t,
    service_name: String.t | nil
  }

  @type headers :: %{
    accept: String.t | nil,
    content_type: String.t | nil,
    request_id: String.t | nil,
    user_agent: String.t | nil
  }

  @recognized_headers ~w(
    accept
    content-type
    user-agent
    x-request-id
  )

  @doc """
  Builds a new struct taking care to normalize data into a valid state. This should
  be used, where possible, instead of creating the struct directly.
  """
  def new(opts) do
    opts =
      opts
      |> Keyword.update(:headers, nil, fn headers -> HTTPUtils.normalize_headers(headers, @recognized_headers) end)
      |> Keyword.update(:method, nil, &HTTPUtils.normalize_method/1)
      |> Keyword.merge(HTTPUtils.normalize_url(Keyword.get(opts, :url)))
      |> Keyword.delete(:url)
      |> Enum.filter(fn {_k,v} -> v != nil end)
    struct!(__MODULE__, opts)
  end

  @doc """
  Message to be used when logging.
  """
  @spec message(t) :: IO.chardata
  def message(%__MODULE__{method: method, path: path, query_string: query_string,
    service_name: service_name}) when not is_nil(service_name),
    do: ["Outgoing HTTP request to ", service_name, " [", method, "] ", HTTPUtils.full_path(path, query_string)]
  def message(%__MODULE__{method: method, path: path, query_string: query_string}),
    do: ["Outgoing HTTP request to [", method, "] ", HTTPUtils.full_path(path, query_string)]
end
