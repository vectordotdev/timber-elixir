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

  @doc """
  Convenience function for encoding a value into JSON using the
  JSON encoded set in `Timber.Config`.
  """
  @spec encode_to_iodata(any) ::
    {:ok, iodata} |
    {:error, Exception.t}
  def encode_to_iodata(value) do
    iodata = Timber.Config.json_encoder().(value)
    {:ok, iodata}
  rescue
    e ->
      {:error, e}
  end
end