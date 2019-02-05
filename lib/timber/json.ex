defmodule Timber.JSON do
  @moduledoc false
  # This module wraps all JSON encoding functions making it easy
  # to change the underlying JSON encoder. This is necessary if/when
  # we decide to make the JSON encoder configurable.

  # Convenience function for encoding data to JSON. This is necessary to allow for
  # configurable JSON parsers.
  @doc false
  @spec encode_to_binary(any) :: {:ok, String.t()} | {:error, term}
  def encode_to_binary(data) do
    Jason.encode(data, escape: :json)
  end

  # Convenience function for encoding data to JSON. This is necessary to allow for
  # configurable JSON parsers.
  @doc false
  @spec encode_to_binary!(any) :: String.t()
  def encode_to_binary!(data) do
    Jason.encode!(data, escape: :json)
  end

  # Convenience function that attempts to encode the provided argument to JSON.
  # If the encoding fails a `nil` value is returned. If you want the actual error
  # please use `encode_to_binary/1`.
  @doc false
  @spec try_encode_to_binary(any) :: nil | String.t()
  def try_encode_to_binary(data) do
    case encode_to_binary(data) do
      {:ok, json} -> json
      {:error, _error} -> nil
    end
  end

  # Convenience function for encoding data to JSON. This is necessary to allow for
  # configurable JSON parsers.
  @doc false
  @spec encode_to_iodata(any) :: {:ok, iodata} | {:error, term}
  def encode_to_iodata(data) do
    Jason.encode_to_iodata(data, escape: :json)
  end

  # Convenience function for encoding data to JSON. This is necessary to allow for
  # configurable JSON parsers.
  @doc false
  @spec encode_to_iodata!(any) :: iodata
  def encode_to_iodata!(data) do
    Jason.encode_to_iodata!(data, escape: :json)
  end

  # Convenience function that attempts to encode the provided argument to JSON.
  # If the encoding fails a `nil` value is returned. If you want the actual error
  # please use `encode_to_iodata/1`.
  @doc false
  @spec try_encode_to_iodata(any) :: nil | iodata
  def try_encode_to_iodata(data) do
    case encode_to_binary(data) do
      {:ok, json} -> json
      {:error, _error} -> nil
    end
  end
end
