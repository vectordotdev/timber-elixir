defmodule Timber.API do
  alias Timber.Config

  @moduledoc false
  # This module is responsible for exposing interacting with the Timber API:
  #
  # http://docs.api.timber.io/

  def send_logs(api_key, content_type, body, opts \\ []) do
    async = Keyword.get(opts, :async, false)
    url = Config.http_url()
    headers = %{"Content-Type" => content_type}
    request(api_key, :post, url, headers: headers, body: body, async: async)
  end

  def handle_async_response(ref, msg) do
    http_client = Config.http_client()
    http_client.handle_async_response(ref, msg)
  end

  def wait_on_response(ref, timeout) do
    http_client = Config.http_client()
    http_client.wait_on_response(ref, timeout)
  end

  #
  # Util
  #

  defp request(api_key, method, url, opts) do
    http_client = Config.http_client()
    auth_token = Base.encode64(api_key)
    vsn = Application.spec(:timber, :vsn)
    user_agent = "timber-elixir/#{vsn}"

    headers =
      opts
      |> Keyword.get(:headers, %{})
      |> Map.put("Authorization", "Basic #{auth_token}")
      |> Map.put("User-Agent", user_agent)

    body = Keyword.get(opts, :body)

    if Keyword.get(opts, :async, false) do
      http_client.async_request(method, url, headers, body)
    else
      http_client.request(method, url, headers, body)
    end
  end
end
