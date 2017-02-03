defmodule Timber.Events.HTTPServerResponseEvent do
  @moduledoc """
  The `HTTPServerResponseEvent` tracks responses for *incoming* HTTP *requests*. In other words,
  the resposnes you are sending back to your clients. This gives you structured insight into
  the response you are sending back to your clients.

  Timber can automatically track response events if you use a `Plug` based framework
  through `Timber.Plug`.
  """

  alias Timber.Utils

  @type t :: %__MODULE__{
    bytes: non_neg_integer,
    headers: headers,
    status: pos_integer,
    time_ms: non_neg_integer
  }

  @type headers :: %{
    cache_control: String.t,
    content_disposition: String.t,
    content_length: non_neg_integer,
    content_type: String.t,
    location: String.t,
    request_id: String.t
  }

  @enforce_keys [:status, :time_ms]
  defstruct [:bytes, :headers, :status, :time_ms]

  @recognized_headers ~w(
    cache_control
    content_disposition
    content_length
    content_type
    location
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
      |> Keyword.update(:headers, nil, fn headers ->
        Utils.normalize_headers(headers, @recognized_headers)
      end)
      |> Enum.filter(fn {_k,v} -> v != nil end)
    struct!(__MODULE__, opts)
  end

  @doc """
  Message to be used when logging.
  """
  @spec message(t) :: IO.chardata
  def message(%__MODULE__{status: status, time_ms: time_ms}),
    do: ["Sent ", status, " in ", time_ms, "ms"]
end
