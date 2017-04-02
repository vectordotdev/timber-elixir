defmodule Timber.Utils.JSON do
  @moduledoc false

  @doc """
  Convenience function for encoding a value into JSON using the
  JSON encoded set in `Timber.Config`.
  """
  @spec encode!(any) :: any
  def encode!(value) do
    Timber.Config.json_encoder().(value)
  end
end