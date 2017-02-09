defmodule Timber.Transports.HTTP.HackneyClient do
  @moduledoc """
  An efficient HTTP client that leverages hackney, keep alive connections, and connection
  pools to communicate with the Timber API.

  ## Configuration

  ```elixir
  config :timber, :hackney_client,
    request_options: [
      connect_timeout: 5_000, # 5 seconds, timeout to connect
      recv_timeout: 20_000 #  20 seconds, timeout to receive a response
    ],
    pool_options: [
      timeout: 600_000, # 10 minutes, how long the connection is kept alive in the pool
      max_connections: 10 # number of connections maintained in the pool
    ]
  ```

  * `:request_options` - Passed to `:hackney.request(method, url, headers, body, request_options)`.
  * `:pool_options` - Passed to `:hackney_pool.start_pool(@pool_name, pool_options)`.

  """

  @behaviour Timber.Transports.HTTP.Client

  @pool_name __MODULE__
  @default_request_options [
    connect_timeout: 5_000, # 5 seconds, timeout to connect
    recv_timeout: 20_000 #  20 seconds, timeout to receive a response
  ]
  @default_pool_options pool_options: [
    timeout: 600_000, # 10 minutes, how long the connection is kept alive in the pool
    max_connections: 10 # number of connections maintained in the pool
  ]

  @doc false
  @spec start() :: :ok
  def start() do
    pool_options = get_pool_options()
    :hackney_pool.start_pool(@pool_name, pool_options)
  end

  defp config, do: Application.get_env(:timber, :hackney_client, [])

  @spec get_pool_options() :: Keyword.t
  defp get_pool_options(), do: Keyword.get(config(), :pool_options, @default_pool_options)

  @spec get_request_options() :: Keyword.t
  defp get_request_options(), do: Keyword.get(config(), :request_options, @default_request_options)

  @doc """
  Issues a HTTP request via hackney.
  """
  def request(method, url, headers, body, opts) do
    req_headers = encode_req_headers(headers)
    req_opts =
      get_request_options()
      |> Keyword.merge(opts)
      |> Keyword.merge([pool: @pool_name, with_body: true])

    :hackney.request(method, url, req_headers, body, req_opts)
  end

  defp encode_req_headers(headers),
    do: Enum.map(headers, &(&1))
end