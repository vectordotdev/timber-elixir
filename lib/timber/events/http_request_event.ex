defmodule Timber.Events.HTTPRequestEvent do
  @moduledoc ~S"""
  **DEPRECATED**

  This module is deprecated in favor of using `map`s. The next evolution of Timber (2.0)
  no long requires a strict schema and therefore simplifies how users set context:

      Logger.info(fn ->
        message = "Received #{method} #{path}"
        event = %{http_request_received: %{method: method, path: path}}
        {message, event: event}
      end)

  Please note, you can use the official
  [`:timber_plug`](https://github.com/timberio/timber-elixir-plug) integration to
  automatically structure this event with metadata.
  """

  alias Timber.Utils.HTTPEvents, as: UtilsHTTPEvents

  @type t :: %__MODULE__{
          body: String.t() | nil,
          direction: String.t() | nil,
          host: String.t() | nil,
          headers: map | nil,
          headers_json: String.t() | nil,
          method: String.t(),
          path: String.t() | nil,
          port: pos_integer | nil,
          query_string: String.t() | nil,
          request_id: String.t() | nil,
          scheme: String.t() | nil,
          service_name: nil | String.t()
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
  @spec new(Keyword.t()) :: t
  def new(opts) do
    opts =
      opts
      |> Keyword.update(:body, nil, fn body -> UtilsHTTPEvents.normalize_body(body) end)
      |> Keyword.update(:headers, nil, fn headers ->
        UtilsHTTPEvents.normalize_headers(headers)
      end)
      |> Keyword.update(:method, nil, &UtilsHTTPEvents.normalize_method/1)
      |> Keyword.update(:service_name, nil, &to_string/1)
      |> Keyword.merge(UtilsHTTPEvents.normalize_url(Keyword.get(opts, :url)))
      |> Keyword.delete(:url)
      |> Enum.filter(fn {_k, v} -> !(v in [nil, ""]) end)
      |> UtilsHTTPEvents.move_headers_to_headers_json()

    struct!(__MODULE__, opts)
  end

  @doc """
  Message to be used when logging.
  """
  @spec message(t) :: IO.chardata()
  def message(%__MODULE__{direction: "outgoing"} = event) do
    message =
      if event.service_name do
        ["Sent ", event.method, " ", event.path]
      else
        full_url =
          UtilsHTTPEvents.full_url(
            event.scheme,
            event.host,
            event.path,
            event.port,
            event.query_string
          )

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

  def message(%__MODULE__{} = event) do
    if event.path do
      ["Received ", event.method, " ", event.path]
    else
      ["Received ", event.method]
    end
  end

  defimpl Timber.Eventable do
    def to_event(%Timber.Events.HTTPRequestEvent{direction: "outgoing"} = event) do
      event = Map.from_struct(event)
      %{http_request_sent: event}
    end

    def to_event(event) do
      event = Map.from_struct(event)
      %{http_request_received: event}
    end
  end
end
