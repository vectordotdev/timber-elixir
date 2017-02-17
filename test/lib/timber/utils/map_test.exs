defmodule Timber.Utils.MapTest do
  use Timber.TestCase

  alias Timber.Utils.Map, as: UtilsMap

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