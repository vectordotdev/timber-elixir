defmodule Timber.Utils.JSON do
  @moduledoc false

  @doc """
  Convenience function for encoding a value into JSON using the
  JSON encoded set in `Timber.Config`.
  """
  @spec encode_to_iodata!(any) :: iodata
  def encode_to_iodata!(value) do
    Timber.Config.json_encoder().(value)
  end
end