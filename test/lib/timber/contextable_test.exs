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
      assert event == %Timber.Contexts.CustomContext{data: %{version: "1.0.0"}, type: :build}
    end

    test "map with multiple root keys" do
      assert_raise FunctionClauseError, fn ->
        map = %{build: %{version: "1.0.0"}, another: 1}
        Contextable.to_context(map)
      end
    end

    test "structured map" do
      map = %{type: :build, data: %{version: "1.0.0"}}
      event = Contextable.to_context(map)
      assert event == %Timber.Contexts.CustomContext{data: %{version: "1.0.0"}, type: :build}
    end

    #
    # Keyword
    #

    test "keyword with a single root key" do
      keyword = [build: %{version: "1.0.0"}]
      event = Contextable.to_context(keyword)
      assert event == %Timber.Contexts.CustomContext{data: %{version: "1.0.0"}, type: :build}
    end

    test "keyword with multiple root keys" do
      assert_raise FunctionClauseError, fn ->
        keyword = [build: %{version: "1.0.0"}, another: 1]
        Contextable.to_context(keyword)
      end
    end

    test "structured keyword" do
      keyword = [type: :build, data: %{version: "1.0.0"}]
      event = Contextable.to_context(keyword)
      assert event == %Timber.Contexts.CustomContext{data: %{version: "1.0.0"}, type: :build}
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
