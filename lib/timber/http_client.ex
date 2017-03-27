defmodule Timber.HTTPClient do
  @moduledoc """
  Behavior for custom HTTP clients. If you opt not to use the default Timber HTTP client
  (`Timber.HTTPClients.Hackney`) you can define your own by adhering to this behavior.

  ## Example

  ```elixir
  defmodule MyHTTPClient do
    alias Timber.HTTPClient

    @behaviour HTTPClient

    @spec request(HTTPClient.method, HTTPClient.url, HTTPClient.headers, HTTPClient.body, HTTPClient.options) ::
      {:ok, HTTPClient.status, HTTPClient.Headers, HTTPClient.body} | {:error, any()}
    def request(method, url, headers, body, opts) do
      # make request here
    end
  end
  ```

  Then specify it in your configuration:

  ```elixir
  config :timber, :http_client, MyHTTPClient
  ```
  """

  @type body :: IO.chardata
  @type headers :: map
  @type method :: atom
  @type status :: pos_integer
  @type url :: String.t
  @type async_result :: {:ok, reference} | {:error, atom}
  @type result :: {:ok, integer, map, String.t} | {:error, atom}

  @callback start() :: :ok
  @callback async_request(method, url, headers, body) :: async_result
  @callback request(method, url, headers, body) :: result
  @callback wait_on_request(reference) :: :ok
end
