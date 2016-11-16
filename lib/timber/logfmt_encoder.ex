defmodule Timber.LogfmtEncoder do
  @moduledoc false
  # Internal module for encoding maps to the logfmt standard

  @spec encode!(map) :: IO.chardata
  def encode!(value) when is_map(value) do
    Enum.reduce(value, [], &encode_pair/2)
  end

  defp encode_pair({k1, value_map}, acc) when is_map(value_map) do
    Enum.reduce(value_map, acc, fn ({k2, v}, a) ->
      encode_pair({[to_string(k1), ?., to_string(k2)], v}, a)
    end)
  end

  defp encode_pair({key, values}, acc) when is_list(values) do
    Enum.reduce(values, acc, fn (value, a)->
      encode_pair({key, value}, a)
    end)
  end

  defp encode_pair({key, value}, acc) do
    add_key_value(key, value, acc)
  end

  defp add_key_value(key, value, []) do
    [to_bin(key), ?=, to_bin(value)]
  end

  defp add_key_value(key, value, acc) do
    [to_bin(key), ?=, to_bin(value), ?\s | acc]
  end

  defp to_bin(value) when is_binary(value) do
    if String.contains?(value, " ") do
      [?", value, ?"]
    else
      value
    end
  end

  defp to_bin(value) do
    to_string(value)
  end
end
