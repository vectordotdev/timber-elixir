defmodule Timber.Events.HTTPClientRequestEvent do
  @moduledoc """
  The `HTTPClientRequestEvent` tracks *outgoing* HTTP requests giving you structured insight
  into communication with external services.

  This event is HTTP client agnostic, use it with your HTTP client of choice.

  ## Hackney Example

    req_method = :get
    req_url = "https://some.api.com/path?query=1"
    req_headers = [{"Accept", "application/json"}]

    # Log the outgoing request
    {req_event, req_message} = Timber.Events.HTTPClientRequestEvent.new_with_message(method: req_method, url: req_url, headers: req_headers)
    Logger.info req_message, event: req_event

    # Make the request
    timer = Timber.Timer.start()
    {:ok, status, headers, body} = :hackney.request(req_method, req_url, req_headers, "")

    # Log the response
    {resp_event, resp_message} = Timber.Events.HTTPClientResponseEvent.new(bytes: 200,
      headers: headers, status: status, timer: timer)
    Logger.info resp_message, event: resp_event

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
  @spec new(Keyword.t) :: t
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
  Convenience methods for creating an event and getting the message at the same time.
  """
  @spec new_with_message(Keyword.t) :: {t, IO.chardata}
  def new_with_message(opts) do
    event = new(opts)
    {event, message(event)}
  end

  @doc """
  Message to be used when logging. The format looks like:

    Outgoing HTTP request to :service_name [GET] /path, ID: :request_id

  Taking care to format the string properly if optional attributes like `:service_name` and
  `:request_id` are not present.

  """
  @spec message(t) :: IO.chardata
  def message(%__MODULE__{headers: headers, host: host, method: method,
    path: path, port: port, query_string: query_string, scheme: scheme, service_name: service_name})
  do
    message = ["Outgoing HTTP request to "]
    message = if service_name,
      do: [message, service_name, " [", method, "] ", HTTPUtils.full_path(path, query_string)],
      else: [message, " [", method, "] ", HTTPUtils.full_url(scheme, host, path, port, query_string)]
    request_id = Map.get(headers || %{}, :request_id)
    message = if request_id,
      do: [message, ", ID ", request_id],
      else: message
    message
  end
end
