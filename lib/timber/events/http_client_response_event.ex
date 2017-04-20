defmodule Timber.Events.HTTPClientResponseEvent do
  @moduledoc """
  The `HTTPClientResponseEvent` tracks responses for *outgoing* HTTP *requests*. This gives you
  structured insight into communication with external services.

  See `Timber.Events.HTTPClientRequestEvent` for examples on track the entire HTTP request
  lifecycle.
  """

  alias Timber.Utils.HTTPEvents, as: UtilsHTTPEvents

  @enforce_keys [:status, :time_ms]
  defstruct [:body, :headers, :request_id, :service_name, :status, :time_ms]

  @type t :: %__MODULE__{
    body: String.t | nil,
    headers: map | nil,
    request_id: String.t | nil,
    service_name: String.t | nil,
    status: pos_integer,
    time_ms: float
  }

  @doc """
  Builds a new struct taking care to:

  * Truncates the body if it is too large.
  * Normalize header values so they are consistent.
  * Removes "" or nil values.
  """
  @spec new(Keyword.t) :: t
  def new(opts) do
    opts =
      opts
      |> Keyword.update(:body, nil, fn body -> UtilsHTTPEvents.normalize_body(body) end)
      |> Keyword.update(:headers, nil, fn headers -> UtilsHTTPEvents.normalize_headers(headers) end)
      |> Keyword.update(:service_name, nil, &UtilsHTTPEvents.try_atom_to_string/1)
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
  Message to be used when logging.
  """
  @spec message(t) :: IO.chardata
  def message(%__MODULE__{request_id: request_id, service_name: service_name, status: status, time_ms: time_ms}) do
    message =
      if request_id do
        truncated_request_id = String.slice(request_id, 0..5)
        ["Outgoing HTTP response (", truncated_request_id, "...) "]
      else
        ["Outgoing HTTP response "]
      end

    message = if service_name,
      do: [message, "from ", service_name, " "],
      else: message

    [message, Integer.to_string(status), " in ", UtilsHTTPEvents.format_time_ms(time_ms)]
  end
end
