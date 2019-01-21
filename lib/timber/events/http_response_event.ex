defmodule Timber.Events.HTTPResponseEvent do
  @moduledoc ~S"""
  **DEPRECATED**

  This module is deprecated in favor of using `map`s. The next evolution of Timber (2.0)
  no long requires a strict schema and therefore simplifies how users set context:

      Logger.info(fn ->
        message = "Sent #{status} response in #{duration_ms}ms"
        event = %{http_response_sent: %{status: status, duration_ms: duration_ms}}
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
          headers: map | nil,
          headers_json: String.t() | nil,
          request_id: String.t() | nil,
          service_name: String.t() | nil,
          status: pos_integer,
          time_ms: float
        }

  @enforce_keys [:status]
  defstruct [
    :body,
    :direction,
    :headers,
    :headers_json,
    :request_id,
    :service_name,
    :status,
    :time_ms
  ]

  @doc """
  Builds a new struct taking care to:

  * Normalize header values so they are consistent.
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
      |> Keyword.update(:service_name, nil, &to_string/1)
      |> Enum.filter(fn {_k, v} -> !(v in [nil, ""]) end)
      |> UtilsHTTPEvents.move_headers_to_headers_json()

    struct!(__MODULE__, opts)
  end

  @doc """
  Message to be used when logging.
  """
  @spec message(t) :: IO.chardata()
  def message(%__MODULE__{direction: "incoming"} = event) do
    message =
      if event.request_id do
        truncated_request_id = String.slice(event.request_id, 0..5)

        [
          "Received ",
          Integer.to_string(event.status),
          " response (",
          truncated_request_id,
          "...)"
        ]
      else
        ["Received ", Integer.to_string(event.status), " response"]
      end

    message =
      if event.service_name,
        do: [message, " from ", event.service_name],
        else: message

    [message, " in ", UtilsHTTPEvents.format_time_ms(event.time_ms)]
  end

  def message(%__MODULE__{} = event),
    do: [
      "Sent ",
      Integer.to_string(event.status),
      " response in ",
      UtilsHTTPEvents.format_time_ms(event.time_ms)
    ]

  defimpl Timber.Eventable do
    def to_event(%Timber.Events.HTTPResponseEvent{direction: "incoming"} = event) do
      event = Map.from_struct(event)
      %{http_response_received: event}
    end

    def to_event(event) do
      event = Map.from_struct(event)
      %{http_response_sent: event}
    end
  end
end
