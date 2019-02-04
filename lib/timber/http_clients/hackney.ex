defmodule Timber.HTTPClients.Hackney do
  @moduledoc false
  # An efficient HTTP client that leverages hackney, keep alive connections, and connection
  # pools to communicate with the Timber API.

  # ## Configuration

  # ```elixir
  # config :timber, :hackney_client,
  #   request_options: [
  #     connect_timeout: 5_000, # 5 seconds, timeout to connect
  #     recv_timeout: 20_000 #  20 seconds, timeout to receive a response
  #   ]
  # ```

  # * `:request_options` - Passed to `:hackney.request(method, url, headers, body, request_options)`.

  alias Timber.HTTPClient

  @behaviour HTTPClient

  @default_request_options [
    # 5 seconds, timeout to connect
    connect_timeout: 5_000,
    #  10 seconds, timeout to receive a response
    recv_timeout: 10_000
  ]

  @doc false
  @impl HTTPClient
  def async_request(method, url, headers, body) do
    req_headers = Enum.map(headers, & &1)

    req_opts =
      get_request_options()
      |> Keyword.merge(async: :once)

    :hackney.request(method, url, req_headers, body, req_opts)
  end

  @doc false
  @impl HTTPClient
  # Legacy response structure for older versions of `:hackney`
  def handle_async_response(ref, {:hackney_response, ref, {:ok, status, body}}) do
    {:ok, status, body}
  end

  # New response structure for current versions of `:hackney`
  def handle_async_response(ref, {:hackney_response, ref, {:status, status, body}}) do
    {:ok, status, body}
  end

  # Return errors since that conforms to the spec
  def handle_async_response(ref, {:hackney_response, ref, {:error, _error} = error_tuple}) do
    error_tuple
  end

  # Pass other messages
  def handle_async_response(_ref, _msg) do
    :pass
  end

  @doc false
  @impl HTTPClient
  def wait_on_response(ref, timeout) do
    receive do
      {:hackney_response, ^ref, _response} = msg ->
        handle_async_response(ref, msg)
    after
      timeout ->
        :timeout
    end
  end

  @doc false
  @impl HTTPClient
  def request(method, url, headers, body) do
    req_headers = Enum.map(headers, & &1)

    req_opts =
      get_request_options()
      |> Keyword.merge(with_body: true)

    :hackney.request(method, url, req_headers, body, req_opts)
  end

  #
  # Config
  #

  @spec config :: Keyword.t()
  defp config, do: Application.get_env(:timber, :hackney_client, [])

  @spec get_request_options() :: Keyword.t()
  defp get_request_options(),
    do: Keyword.get(config(), :request_options, @default_request_options)
end
