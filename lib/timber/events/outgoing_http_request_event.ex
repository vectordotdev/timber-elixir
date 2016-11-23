defmodule Timber.Events.OutgoingHTTPRequest do
  @moduledoc """
  The OutgoingHTTPRequest event tracks outgoing HTTP requests.

  Because of the variety of HTTP libraries, implementation is left to the user.
  Good news! Implementation is relatively simple (see the examples below).

  By implementing this event, Timber can make assumptions about your data, such as
  automatically creating graphs for service response times.

  ## Examples


  """

  @type t :: %__MODULE__{
    scheme: String.t,
    method: String.t,
    host: String.t,
    path: String.t,
    query: String.t,
    status: integer(),
    time_ms: float()
  }

  defstruct [:scheme, :method, :host, :path, :query, :status, :time_ms]

  @spec new(Keyword.t) :: t
  def new(opts) do
    url = Keyword.get(opts, :url)
    opts =
      if url do
        uri = URI.parse(url)
        opts
        |> Keyword.delete(:url)
        |> Keyword.put(:scheme, uri.scheme)
        |> Keyword.put(:host, uri.authority)
        |> Keyword.put(:path, uri.path)
        |> Keyword.put(:query, uri.query)
      else
        opts
      end

    struct(__MODULE__, opts)
  end

  @spec message(t) :: IO.chardata
  def message(%__MODULE__{method: method, status: status, time_ms: time_ms} = event),
    do: "Outgoing HTTP request to [#{method}] #{url(event)} received #{status} in #{time_ms}ms"

  @spec url(t) :: String.t
  def url(%__MODULE__{scheme: scheme, host: host, path: path, query: query}) do
    base = "#{scheme}#{host}#{path}"
    if query do
      "#{base}?#{query}"
    else
      base
    end
  end
end
