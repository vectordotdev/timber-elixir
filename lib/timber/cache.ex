defmodule Timber.Cache do
  @moduledoc false

  @doc """
  Creates the ets table and inserts initial values.
  """
  def init do
    update_hostname()
    :ok
  end

  @doc """
  Fetches the cached system hostname.
  """
  def hostname do
    Application.get_env(:timber, :hostname)
  end

  @doc """
  Updates the cached system hostname from inets
  """
  def update_hostname do
    Application.put_env(:timber, :hostname, inet_hostname())
  end

  defp inet_hostname do
    {:ok, hostname} = :inet.gethostname()
    to_string(hostname)
  end
end
