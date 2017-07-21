defmodule Timber.Events.HTTPResponseEvent do
  @moduledoc """
  The `HTTPResponseEvent` tracks HTTP responses in your app, both outgoing and
  incoming from external services (should you choose to track these). This gives
  you structured insight into all of your HTTP response events.

  Timber can automatically track response events if you use a `Plug` based framework
  through `Timber.Plug`.
  """

  alias Timber.Utils.HTTPEvents, as: UtilsHTTPEvents

  @type t :: %__MODULE__{
    body: String.t | nil,
    direction: String.t | nil,
    headers: map | nil,
    headers_json: String.t | nil,
    request_id: String.t | nil,
    service_name: String.t | nil,
    status: pos_integer,
    time_ms: float
  }

  @enforce_keys [:status, :time_ms]
  defstruct [:body, :direction, :headers, :headers_json, :request_id, :service_name, :status,
    :time_ms]

  @doc """
  Builds a new struct taking care to:

  * Normalize header values so they are consistent.
  * Removes "" or nil values.
  """
  @spec new(Keyword.t) :: t
  def new(opts) do
    opts =
      opts
      |> Keyword.delete(:body) # Don't store the body for now. We store the params in the ControllerCallEvent. We can re-enable this upon request.
      |> Keyword.update(:headers, nil, fn headers -> UtilsHTTPEvents.normalize_headers(headers) end)
      |> Enum.filter(fn {_k,v} -> !(v in [nil, ""]) end)
      |> UtilsHTTPEvents.move_headers_to_headers_json()

    struct!(__MODULE__, opts)
  end

  @doc """
  Message to be used when logging.
  """
  @spec message(t) :: IO.chardata
  def message(%__MODULE__{direction: "incoming"} = event) do
    message =
      if event.request_id do
        truncated_request_id = String.slice(event.request_id, 0..5)
        ["Incoming HTTP response (", truncated_request_id, "...) "]
      else
        ["Incoming HTTP response "]
      end

    message = if event.service_name,
      do: [message, "from ", to_string(event.service_name), " "],
      else: message

    [message, Integer.to_string(event.status), " in ", UtilsHTTPEvents.format_time_ms(event.time_ms)]
  end

  def message(%__MODULE__{} = event),
    do: ["Sent ", Integer.to_string(event.status), " in ", UtilsHTTPEvents.format_time_ms(event.time_ms)]
end
