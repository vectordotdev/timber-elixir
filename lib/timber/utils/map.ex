defmodule Timber.Utils.Map do
  @moduledoc false

  @doc """
  Recursively drops keys with blank values in a map.
  """
  def recursively_drop_blanks(map) when is_map(map) do
    Enum.reduce map, %{}, fn
      {k, v}, acc when is_map(v) ->
        new_v = recursively_drop_blanks(v)
        if map_size(new_v) > 0 do
          Map.put(acc, k, new_v)
        else
          acc
        end
      {_k, nil}, acc -> acc
      {_k, ""}, acc -> acc
      {_k, []}, acc -> acc
      {k, v}, acc -> Map.put(acc, k, v)
    end
  end
end