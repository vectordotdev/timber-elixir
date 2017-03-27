defmodule Mix.Tasks.Timber.Install.Config do
  @moduledoc false

  alias Mix.Tasks.Timber.Install.HTTPClient

  def api_url do
    default_api_url = "https://api.timber.io"
    Keyword.get(config(), :api_url, default_api_url)
  end

  def file_client do
    Keyword.get(config(), :file_client, File)
  end

  def http_client do
    Keyword.get(config(), :http_client, HTTPClient)
  end

  def io_client do
    Keyword.get(config(), :io_client, IO)
  end

  def path_client do
    Keyword.get(config(), :path_client, Path)
  end

  defp config do
    Application.get_env(:timber, :install, [])
  end
end
