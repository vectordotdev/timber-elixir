defmodule Timber.ContextTest do
  use Timber.TestCase

  alias Timber.Context

  describe "Timber.Context.add/2" do
    test "custom context with a symbol type" do
      custom_context = %Timber.Contexts.CustomContext{type: :build, data: %{version: "1.0.0"}}
      result = Context.add(%{}, custom_context)
      assert result ==  %{custom: %{build: %{version: "1.0.0"}}}
    end

    test "custom context with a string type" do
      custom_context = %Timber.Contexts.CustomContext{type: "build", data: %{version: "1.0.0"}}
      result = Context.add(%{}, custom_context)
      assert result ==  %{custom: %{build: %{version: "1.0.0"}}}
    end

    test "user context with an integer id" do
      user_context = %Timber.Contexts.UserContext{id: 1}
      result = Context.add(%{}, user_context)
      assert result ==  %{user: %{id: "1"}}
    end

    test "user context with a string id" do
      user_context = %Timber.Contexts.UserContext{id: "1"}
      result = Context.add(%{}, user_context)
      assert result ==  %{user: %{id: "1"}}
    end
  end
end