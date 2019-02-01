defmodule Timber.Events.HTTPRequestEvent do
  @deprecated_message ~S"""
  The `Timber.Events.HTTPRequestEvent` module is deprecated in favor of using `map`s.

  The next evolution of Timber (2.0) no long requires a strict schema and therefore
  simplifies how users log events.

  To easily migrate, please install the `:timber_plug` library:

  https://github.com/timberio/timber-elixir-plug
  """

  @moduledoc """
  **DEPRECATED**

  #{@deprecated_message}
  """

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

  @doc false
  @deprecated @deprecated_message
  @spec new(Keyword.t()) :: t
  def new(opts) do
    opts =
      opts
      |> Keyword.delete(:body)
      |> Keyword.delete(:headers)

    struct!(__MODULE__, opts)
  end

  @doc false
  @deprecated @deprecated_message
  @spec message(t) :: IO.chardata()
  def message(%__MODULE__{direction: "outgoing"} = event) do
    message =
      if event.service_name do
        ["Sent ", event.method, " ", event.path]
      else
        full_url =
          build_full_url(
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

  def message(%__MODULE__{} = event),
    do: ["Received ", event.method, " ", event.path]

  defp build_full_url(scheme, host, path, port, query_string) do
    %URI{scheme: scheme, host: host, path: path, port: port, query: query_string}
    |> URI.to_string()
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
