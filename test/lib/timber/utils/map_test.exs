defmodule Timber.Utils.MapTest do
  defmodule TestStruct do
    defstruct [:key]
  end

  use Timber.TestCase

  alias Timber.Utils.Map, as: UtilsMap

  describe "Timber.Utils.Map.deep_from_struct/1" do
    test "normalizes a struct into maps" do
      m = %{key: %Timber.Contexts.UserContext{id: 1}}
      r = UtilsMap.deep_from_struct(m)
      assert r == %{key: %{id: 1, email: nil, name: nil}}
    end

    test "normalizes a datetime into a map value" do
      now = DateTime.utc_now()
      m = %{key: now}
      r = UtilsMap.deep_from_struct(m)
      iso_8601 = DateTime.to_iso8601(now)
      assert r == %{key: iso_8601}
    end

    test "handles tuples" do
      struct = %TestStruct{key: %TestStruct{key: {1, {2, 3}}}}
      m = %{a: struct}
      r = UtilsMap.recursively_drop_blanks(m)
      assert r == %{a: %{key: %{key: {1, {2, 3}}}}}
    end
  end

  describe "Timber.Utils.Map.recursively_drop_blanks/1" do
    test "drops blank maps" do
      m = %{a: %{}, b: 1}
      r = UtilsMap.recursively_drop_blanks(m)
      assert r == %{b: 1}
    end

    test "drops nested blank maps" do
      m = %{a: %{a: %{a: %{}}}, b: 1}
      r = UtilsMap.recursively_drop_blanks(m)
      assert r == %{b: 1}
    end

    test "drops nils" do
      m = %{a: nil, b: 1}
      r = UtilsMap.recursively_drop_blanks(m)
      assert r == %{b: 1}
    end

    test "drops blank strings" do
      m = %{a: "", b: 1}
      r = UtilsMap.recursively_drop_blanks(m)
      assert r == %{b: 1}
    end

    test "drops blank arrays" do
      m = %{a: [], b: 1}
      r = UtilsMap.recursively_drop_blanks(m)
      assert r == %{b: 1}
    end

    test "keeps nested hashes intact" do
      m = %{a: %{a: %{a: %{}, b: 1, c: nil}}, b: 1}
      r = UtilsMap.recursively_drop_blanks(m)
      assert r == %{b: 1, a: %{a: %{b: 1}}}
    end
  end
end
