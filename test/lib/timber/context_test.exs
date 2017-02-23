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

    test "organization context with an integer id" do
      organization_context = %Timber.Contexts.OrganizationContext{id: 1}
      result = Context.add(%{}, organization_context)
      assert result ==  %{organization: %{id: "1"}}
    end

    test "organization context with a string id" do
      organization_context = %Timber.Contexts.OrganizationContext{id: "1"}
      result = Context.add(%{}, organization_context)
      assert result ==  %{organization: %{id: "1"}}
    end

    test "system context with an integer id" do
      user_context = %Timber.Contexts.SystemContext{pid: 1}
      result = Context.add(%{}, user_context)
      assert result ==  %{system: %{pid: "1"}}
    end

    test "system context with a string id" do
      user_context = %Timber.Contexts.SystemContext{pid: "1"}
      result = Context.add(%{}, user_context)
      assert result ==  %{system: %{pid: "1"}}
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