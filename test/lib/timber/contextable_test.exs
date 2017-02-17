defmodule Timber.ContextableTest do
  use Timber.TestCase

  alias Timber.Contextable

  describe "Timber.Contextable.to_event/1" do
    test "map with a single root key" do
      event = Contextable.to_context(%{build: %{version: "1.0.0"}})
      assert event == %Timber.Contexts.CustomContext{data: %{version: "1.0.0"}, type: :build}
    end

    test "map with multiple root keys" do
      assert_raise FunctionClauseError, fn ->
        Contextable.to_context(%{build: %{version: "1.0.0"}, another: 1})
      end
    end

    test "structured map" do
      event = Contextable.to_context(%{type: :build, data: %{version: "1.0.0"}})
      assert event == %Timber.Contexts.CustomContext{data: %{version: "1.0.0"}, type: :build}
    end
  end
end