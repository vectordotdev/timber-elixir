defmodule Timber.Events.HTTPServerResponseEvent do
  @moduledoc """
  The `HTTPServerResponseEvent` tracks responses for *incoming* HTTP *requests*. In other words,
  the resposnes you are sending back to your clients. This gives you structured insight into
  the response you are sending back to your clients.

  Timber can automatically track response events if you use a `Plug` based framework
  through `Timber.Plug`.
  """

  alias Timber.Utils.HTTPEvents, as: UtilsHTTPEvents

  @type t :: %__MODULE__{
    body: String.t | nil,
    headers: map,
    request_id: Strin.t | nil,
    status: pos_integer,
    time_ms: float
  }

  @enforce_keys [:status, :time_ms]
  defstruct [:body, :headers, :request_id, :status, :time_ms]

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

    struct!(__MODULE__, opts)
  end

  @doc """
  Message to be used when logging.
  """
  @spec message(t) :: IO.chardata
  def message(%__MODULE__{status: status, time_ms: time_ms}),
    do: ["Sent ", Integer.to_string(status), " in ", UtilsHTTPEvents.format_time_ms(time_ms)]
end
