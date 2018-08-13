defmodule Timber.Cache do
  @moduledoc """
  This module is responsible for caching values that are
  expensive to get or compute.
  """
  @table_name :timber_cache

  @doc """
  Creates the ets table and inserts initial values.
  """
  def init do
    :ets.new(@table_name, [:named_table, :set, :public, read_concurrency: true])

    update_hostname()
    :ok
  end

  @doc """
  Fetches the cached system hostname.
  """
  def hostname do
    case :ets.lookup(@table_name, :hostname) do
      [{:hostname, hostname}] -> hostname
      _ -> nil
    end
  end

  @doc """
  Updates the cached system hostname from inets
  """
  def update_hostname do
    :ets.insert(@table_name, {:hostname, inet_hostname()})
  end

  defp inet_hostname do
    {:ok, hostname} = :inet.gethostname()
    to_string(hostname)
  end
end
