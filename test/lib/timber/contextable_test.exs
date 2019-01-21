defmodule Timber.ContextableTest do
  use Timber.TestCase

  alias Timber.Contextable

  describe "Timber.Contextable.to_event/1" do
    #
    # Map
    #

    test "map with a single root key" do
      map = %{build: %{version: "1.0.0"}}
      event = Contextable.to_context(map)
      assert event == %{build: %{version: "1.0.0"}}
    end

    test "map with multiple root keys" do
      map = %{build: %{version: "1.0.0"}, another: 1}
      context = Contextable.to_context(map)
      assert context == map
    end

    test "structured map" do
      map = %{type: :build, data: %{version: "1.0.0"}}
      event = Contextable.to_context(map)
      assert event == %{build: %{version: "1.0.0"}}
    end

    #
    # Keyword
    #

    test "keyword with a single root key" do
      keyword = [build: %{version: "1.0.0"}]
      event = Contextable.to_context(keyword)
      assert event == %{build: %{version: "1.0.0"}}
    end

    test "keyword with multiple root keys" do
      keyword = [build: %{version: "1.0.0"}, another: 1]
      context = Contextable.to_context(keyword)
      assert context == %{another: 1, build: %{version: "1.0.0"}}
    end

    test "structured keyword" do
      keyword = [type: :build, data: %{version: "1.0.0"}]
      event = Contextable.to_context(keyword)
      assert event == %{build: %{version: "1.0.0"}}
    end

    #
    # List
    #

    test "generic list" do
      assert_raise RuntimeError,
                   "The provided list is not a Keyword.t and therefore cannot be converted to a Timber context",
                   fn ->
                     list = [:key]
                     Contextable.to_context(list)
                   end
    end
  end
end
