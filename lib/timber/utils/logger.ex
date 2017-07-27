defmodule Timber.Utils.Logger do
  @moduledoc false

  @doc """
  Truncate a binary to the given length, taking into account the " (truncated)"
  suffix that the Logger.Utils.truncate/1 method appends.
  """
  @spec truncate_bytes(IO.chardata, pos_integer) :: IO.chardata
  def truncate_bytes(chardata, byte_limit) do
    adjusted_byte_limit = byte_limit - 15 # takes into account the " (truncated)" string that the below function appends
    Logger.Utils.truncate(chardata, adjusted_byte_limit)
  end
end