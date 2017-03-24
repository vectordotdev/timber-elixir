if Code.ensure_loaded?(:hackney) do
  defmodule Timber.HTTPClients.Hackney do
    @moduledoc """
    An efficient HTTP client that leverages hackney, keep alive connections, and connection
    pools to communicate with the Timber API.

    ## Configuration

    ```elixir
    config :timber, :hackney_client,
      request_options: [
        connect_timeout: 5_000, # 5 seconds, timeout to connect
        recv_timeout: 20_000 #  20 seconds, timeout to receive a response
      ]
    ```

    * `:request_options` - Passed to `:hackney.request(method, url, headers, body, request_options)`.

    """

    alias Timber.HTTPClient

    @behaviour HTTPClient

    @default_request_options [
      connect_timeout: 5_000, # 5 seconds, timeout to connect
      recv_timeout: 10_000 #  10 seconds, timeout to receive a response
    ]

    def start() do
      {:ok, _} = Application.ensure_all_started(:hackney)

      :ok
    end

    @doc """
    Issues a HTTP request via hackney.
    """
    def async_request(method, url, headers, body) do
      req_headers = Enum.map(headers, &(&1))
      req_opts =
        get_request_options()
        |> Keyword.merge([async: true])

      :hackney.request(method, url, req_headers, body, req_opts)
    end

    @doc """
    Issues a HTTP request via hackney.
    """
    def request(method, url, headers, body) do
      req_headers = Enum.map(headers, &(&1))
      req_opts =
        get_request_options()
        |> Keyword.merge([with_body: true])

      :hackney.request(method, url, req_headers, body, req_opts)
    end

    @doc """
    Takes a reference to an async request and waits for it to complete.
    """
    @spec wait_on_request(reference) :: :ok
    def wait_on_request(ref) do
      receive do
        {:hackney_response, ^ref, {:ok, status, reason}} ->
          Timber.debug fn -> "HTTP request #{inspect(ref)} received response #{status} #{reason}" end
          wait_on_request(ref)

        {:hackney_response, ^ref, {:error, error}} ->
          Timber.debug fn -> "HTTP request #{inspect(ref)} received error #{inspect(error)}" end
          wait_on_request(ref)

        {:hackney_response, ^ref, :done} ->
          Timber.debug fn -> "HTTP request #{inspect(ref)} done" end
          :ok

        _else -> wait_on_request(ref)
      end
    end

    #
    # Config
    #

    @spec config :: Keyword.t
    defp config, do: Application.get_env(:timber, :hackney_client, [])

    @spec get_request_options() :: Keyword.t
    defp get_request_options(), do: Keyword.get(config(), :request_options, @default_request_options)
  end
end
