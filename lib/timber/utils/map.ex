defmodule Timber.Utils.Map do
  @moduledoc false

  def deep_from_struct(%{__struct__: _mod} = struct) do
    struct
    |> Map.from_struct()
    |> deep_from_struct()
  end

  def deep_from_struct(map) when is_map(map) do
    map
    |> Enum.reduce(%{}, fn
      {k, %DateTime{} = v}, acc ->
        Map.put(acc, k, DateTime.to_iso8601(v))

      {k, v}, acc when is_map(v) ->
        new_v = deep_from_struct(v)
        Map.put(acc, k, new_v)

      {k, v}, acc ->
        Map.put(acc, k, v)
    end)
  end

  @doc """
  Recursively drops keys with blank values in a map.
  """
  def recursively_drop_blanks(%{__struct__: _mod} = struct) do
    struct
    |> Map.from_struct()
    |> recursively_drop_blanks()
  end

  def recursively_drop_blanks(map) when is_map(map) do
    map
    |> Enum.reduce(%{}, fn
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
    end)
  end
end