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

  alias Timber.Transports.HTTP.Client

  @behaviour Client

  @pool_name __MODULE__
  @default_request_options [
    connect_timeout: 5_000, # 5 seconds, timeout to connect
    recv_timeout: 10_000 #  10 seconds, timeout to receive a response
  ]
  @default_pool_options pool_options: [
    timeout: 600_000, # 10 minutes, how long the connection is kept alive in the pool
    max_connections: 2 # number of connections maintained in the pool
  ]

  @doc false
  def start_link do
    children = [:hackney_pool.child_spec(@pool_name, get_pool_options())]
    opts = [strategy: :one_for_one, name: __MODULE__.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp config, do: Application.get_env(:timber, :hackney_client, [])

  @doc false
  @spec get_pool_options() :: Keyword.t
  def get_pool_options(), do: Keyword.get(config(), :pool_options, @default_pool_options)

  @doc false
  @spec get_request_options() :: Keyword.t
  defp get_request_options(), do: Keyword.get(config(), :request_options, @default_request_options)

  @doc """
  Issues a HTTP request via hackney.
  """
  @spec async_request(Client.method, Client.url, Client.headers, Client.body) :: Client.result
  def async_request(method, url, headers, body) do
    req_headers = Enum.map(headers, &(&1))
    req_opts =
      get_request_options()
      |> Keyword.merge([pool: @pool_name, async: true])

    :hackney.request(method, url, req_headers, body, req_opts)
  end

  @doc """
  Takes a process message type and body and determines if the async request sent in
  `async_request/5` is complete.
  """
  @spec done?(reference, any) :: boolean
  def done?(ref, {:hackney_response, message_ref, :done}) when ref == message_ref, do: true
  def done?(_ref, _message), do: false
end