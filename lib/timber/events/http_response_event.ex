defmodule Timber.Events.HTTPResponseEvent do
  @deprecated_message ~S"""
  The `Timber.Events.HTTPResponseEvent` module is deprecated in favor of using `map`s.

  The next evolution of Timber (2.0) no long requires a strict schema and therefore
  simplifies how users log events.

  To easily migrate, please install the `:timber_plug` library:

  https://github.com/timberio/timber-elixir-plug
  """

  @moduledoc ~S"""
  **DEPRECATED**

  #{@deprecated_message}
  """

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

    [message, " in ", Timber.format_time_ms(event.time_ms)]
  end

  def message(%__MODULE__{} = event),
    do: [
      "Sent ",
      Integer.to_string(event.status),
      " response in ",
      Timber.format_time_ms(event.time_ms)
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
