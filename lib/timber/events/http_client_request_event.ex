defmodule Timber.Events.HTTPClientRequestEvent do
  @moduledoc """
  The `HTTPClientRequestEvent` tracks *outgoing* HTTP requests giving you structured insight
  into communication with external services.

  This event is HTTP client agnostic, use it with your HTTP client of choice.

  ## Hackney Example

  ```elixir
  req_method = :get
  req_url = "https://some.api.com/path?query=1"
  req_headers = [{"Accept", "application/json"}]
  req_body = "{\"example\": \"payload\"}"

  # Log the outgoing request
  {req_event, req_message} = Timber.Events.HTTPClientRequestEvent.new_with_message(method: req_method, url: req_url, headers: req_headers, body: req_body)
  Logger.info req_message, event: req_event

  # Make the request
  timer = Timber.start_timer()
  {:ok, status, headers, body} = :hackney.request(req_method, req_url, req_headers, "")

  # Log the response
  time_ms = Timber.duration_ms(timer)
  {resp_event, resp_message} = Timber.Events.HTTPClientResponseEvent.new(headers: headers, body: body, status: status, time_ms: time_ms)
  Logger.info resp_message, event: resp_event
  ```

  """

  alias Timber.Utils.HTTPEvents, as: UtilsHTTPEvents

  @enforce_keys [:host, :method, :scheme]
  defstruct [:body, :headers, :host, :method, :path, :port, :query_string, :request_id, :scheme,
    :service_name]

  @type t :: %__MODULE__{
    body: String.t | nil,
    headers: map | nil,
    host: String.t,
    method: String.t,
    path: String.t | nil,
    port: pos_integer | nil,
    query_string: String.t | nil,
    request_id: String.t | nil,
    scheme: String.t,
    service_name: String.t | nil
  }

  @doc """
  Builds a new struct taking care to:

  * Parsing the `:url` and mapping it to the appropriate attributes.
  * Truncate the body if it is too large.
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
      |> Keyword.update(:service_name, nil, &UtilsHTTPEvents.try_atom_to_string/1)
      |> Keyword.merge(UtilsHTTPEvents.normalize_url(Keyword.get(opts, :url)))
      |> Keyword.delete(:url)
      |> Enum.filter(fn {_k,v} -> !(v in [nil, ""]) end)

    opts = Keyword.put_new_lazy(opts, :request_id, fn -> UtilsHTTPEvents.get_request_id_from_headers(opts[:headers]) end)

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
  def message(%__MODULE__{host: host, method: method, path: path, port: port,
    query_string: query_string, scheme: scheme, service_name: service_name})
  do
    message = ["Outgoing HTTP request to "]

    if service_name,
      do: [message, service_name, " [", method, "] ", UtilsHTTPEvents.full_path(path, query_string)],
      else: [message, "[", method, "] ", UtilsHTTPEvents.full_url(scheme, host, path, port, query_string)]
  end
end
