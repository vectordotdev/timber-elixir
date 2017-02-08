defmodule Timber.Transports.HTTP.HackneyClient do
  @moduledoc """
  A highly efficient HTTP client that leverages hackney, keep alive connections, connection pools,
  and fuses to efficiently, and properly, communicate with the Timber API.

  ## Configuration

  ```elixir
  config :timber, :hackney_client,
    fuse_options: {{:standard, 1, 60_000}, {:reset, 60_000}},
    request_options: [
      connect_timeout: 5_000, # 5 seconds, timeout to connect
      recv_timeout: 20_000 #  20 seconds, timeout to receive a response
    ],
    pool_options: [
      timeout: 600_000, # 10 minutes, how long the connection is kept alive in the pool
      max_connections: 10 # number of connections maintained in the pool
    ]
  ```

  * `fuse_options` - Options are passed to `:fuse.install(@fuse_name, fuse_options)`. See
    [the fuse project](https://github.com/jlouis/fuse)
  * `:request_options` - Passed to `:hackney.request(method, url, headers, body, request_options)`.
  * `:pool_options` - Passed to `:hackney_pool.start_pool(@pool_name, pool_options)`.

  ## Fuse

  Fuse will back off communication in the event the Timber API does not response with a 2XX.
  """

  @behaviour Timber.Transports.HTTP.Client

  @fuse_name __MODULE__
  @pool_name __MODULE__
  @default_fuse_options {{:standard, 1, 60_000}, {:reset, 60_000}}
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
    fuse_options = get_fuse_options()
    pool_options = get_pool_options()

    :ok = :fuse.install(@fuse_name, fuse_options)
    :ok = :hackney_pool.start_pool(@pool_name, pool_options)

    :ok
  end

  defp config, do: Application.get_env(:timber, :hackney_client, [])

  @spec get_fuse_options() :: {{:standard, integer, integer}, {:reset, integer}}
  defp get_fuse_options(), do: Keyword.get(config(), :fuse_options, @default_fuse_options)

  @spec get_pool_options() :: Keyword.t
  defp get_pool_options(), do: Keyword.get(config(), :pool_options, @default_pool_options)

  @spec get_request_options() :: Keyword.t
  defp get_request_options(), do: Keyword.get(config(), :request_options, @default_request_options)

  @doc """
  Issues request via hackney respecting the :fuse status and leveraging the connection pool.
  """
  def request(method, url, headers, body, opts) do
    case :fuse.ask(@fuse_name, :sync) do
      :ok ->
        req_opts =
          get_request_options()
          |> Keyword.merge(opts)
          |> Keyword.merge([pool: @pool_name, with_body: true])

        case :hackney.request(method, url, headers, body, req_opts) do
          {:ok, status, headers, body} ->
            maintain_fuse(status)
            {:ok, statue, headers, body}
          {:error, error} ->
            {:error, error}
        end
      :blown ->
        {:error, :fuse_blown}
      {:error, :not_found} ->
        {:error, :not_found}
    end
  end

  # Maintains the fuse status based on the Timber API response.
  defp maintain_fuse(status) when status in [401, 403, 429] or status in 500..599 do
    :fuse.melt(@fuse_name)
  end
  defp maintain_fuse(_status) do
    :ok
  end
end