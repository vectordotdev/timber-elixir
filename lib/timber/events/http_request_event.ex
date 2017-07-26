defmodule Timber.Events.HTTPRequestEvent do
  @moduledoc """
  The `HTTPRequestEvent` tracks HTTP requests as defined by the Timber log event JSON schema:
  https://github.com/timberio/log-event-json-schema

  This gives you structured into the HTTP request
  coming into your app as well as the ones going out (if you choose to track them).

  Timber can automatically track incoming HTTP requests if you use a `Plug` based framework.
  See the documentation for `Timber.Integerations.EventPlug` for more information. The `README.md`
  also outlines how to set this up.
  """

  alias Timber.Utils.HTTPEvents, as: UtilsHTTPEvents

  @type t :: %__MODULE__{
    body: String.t | nil,
    direction: String.t | nil,
    host: String.t,
    headers: map | nil,
    headers_json: String.t | nil,
    method: String.t,
    path: String.t | nil,
    port: pos_integer | nil,
    query_string: String.t | nil,
    request_id: String.t | nil,
    scheme: String.t,
    service_name: nil | String.t
  }

  @enforce_keys [:method]
  defstruct [
    :body,
    :direction,
    :host,
    :headers,
    :headers_json,
    :method,
    :path,
    :port,
    :query_string,
    :request_id,
    :scheme,
    :service_name
  ]

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
      |> Keyword.update(:body, nil, fn body -> UtilsHTTPEvents.normalize_body(body) end)
      |> Keyword.update(:headers, nil, fn headers -> UtilsHTTPEvents.normalize_headers(headers) end)
      |> Keyword.update(:method, nil, &UtilsHTTPEvents.normalize_method/1)
      |> Keyword.update(:service_name, nil, &to_string/1)
      |> Keyword.merge(UtilsHTTPEvents.normalize_url(Keyword.get(opts, :url)))
      |> Keyword.delete(:url)
      |> Enum.filter(fn {_k,v} -> !(v in [nil, ""]) end)
      |> UtilsHTTPEvents.move_headers_to_headers_json()

    struct!(__MODULE__, opts)
  end

  @doc """
  Message to be used when logging.
  """
  @spec message(t) :: IO.chardata
  def message(%__MODULE__{direction: "outgoing"} = event) do
    message =
      if event.service_name do
        ["Sent ", event.method, " ", event.path]
      else
        full_url = UtilsHTTPEvents.full_url(event.scheme, event.host, event.path, event.port, event.query_string)
        ["Sent ", event.method, " ", full_url]
      end

    message =
      if event.request_id do
        truncated_request_id = String.slice(event.request_id, 0..5)
        [message, " (", truncated_request_id, "...)"]
      else
        message
      end

    if event.service_name,
      do: [message, " to ", event.service_name],
      else: message
  end

  def message(%__MODULE__{} = event),
    do: ["Received ", event.method, " ", event.path]
end
