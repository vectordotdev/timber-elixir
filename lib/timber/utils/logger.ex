defmodule Timber.Utils.Logger do
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
end