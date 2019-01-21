defmodule Timber.Event do
  @moduledoc false
  # This module is internal to the Timber library and should not be called directly
  # by users.

  alias Timber.Eventable

  #
  # Typespecs
  #

  @type t :: %{required(key) => value}
  @type key :: atom | String.t()
  @type value :: %{optional(key) => boolean | number | String.t() | value}

  #
  # API
  #

  @doc false
  @spec extract_from_metadata(Keyword.t()) :: nil | t
  def extract_from_metadata(metadata) do
    Keyword.get(metadata, Timber.Config.event_key(), nil)
  end

  @doc false
  def to_event(data) do
    Eventable.to_event(data)
  end

  @doc false
  @spec to_metadata(t) :: Keyword.t()
  def to_metadata(event) do
    Keyword.put([], Timber.Config.event_key(), event)
  end
end
