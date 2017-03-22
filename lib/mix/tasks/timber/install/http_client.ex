defmodule Mix.Tasks.Timber.Install.HTTPClient do
  @moduledoc false

  def start do
    case :inets.start() do
      :ok -> :ok
      {:error, {:already_started, _name}} -> :ok
      other -> other
    end

    case :ssl.start() do
      :ok -> :ok
      {:error, {:already_started, _name}} -> :ok
      other -> other
    end
  end

  def request(method, headers, url, opts \\ []) when method in [:get, :post] do
    vsn = Application.spec(:timber, :vsn)
    headers = headers ++ [{'User-Agent', 'Timber Elixir/#{vsn} (HTTP)'}]
    body =
      Keyword.get(opts, :body, "")
      |> encode_body()

    case do_request(method, url, headers, body) do
      {:ok, {{_protocol, status, _status_name}, _headers, body}} ->
        {:ok, status, body}

      {:error, reason} -> {:error, reason}
    end
  end

  defp do_request(:get, url, headers, _body) do
    :httpc.request(:get, {String.to_charlist(url), headers}, [], [])
  end

  defp do_request(:post, url, headers, []) do
    :httpc.request(:post, {String.to_charlist(url), headers, [], []}, [], [])
  end

  defp do_request(:post, url, headers, body) do
    :httpc.request(:post, {String.to_charlist(url), headers, 'application/json', body}, [], [])
  end

  defp encode_body(body) when is_map(body) do
    Poison.encode!(body)
  end

  defp encode_body(body) when is_binary(body), do: String.to_charlist(body)
end