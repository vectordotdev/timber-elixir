defmodule Timber.Utils.Logger do
  @moduledoc false

  @doc """
  Convenience function for using the metadata logger key specified in the configuration.
  This is equivalent to:

  ## Examples

  ```elixir
  metadata = Timber.Utils.Logger.event_to_metadata(event)
  Logger.info("my message", metadata)
  ```
  """
  @spec event_to_metadata(Timber.Event.t) :: Keyword.t
  def event_to_metadata(event) do
    Keyword.put([], Timber.Config.event_key(), event)
  end

  @spec get_event_from_metadata(Keyword.t) :: nil | Timber.Event.t
  def get_event_from_metadata(metadata) do
    Keyword.get(metadata, Timber.Config.event_key(), nil)
  end

  @doc """
  Truncate a binary to the given length, taking into account the " (truncated)"
  suffix that the Logger.Utils.truncate/1 method appends.
  """
  @spec truncate(IO.chardata, pos_integer) :: IO.chardata
  def truncate(chardata, limit) do
    adjusted_limit = limit - 15 # takes into account the " (truncated)" string that the below function appends
    Logger.Utils.truncate(chardata, adjusted_limit)
  end
end