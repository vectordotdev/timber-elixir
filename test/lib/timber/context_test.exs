defmodule Timber.ContextTest do
  use Timber.TestCase

  alias Timber.Context

  describe "Timber.Context.add/2" do
    test "keyword list" do
      result = Context.add(%{}, key1: %{value1: "value"}, key2: %{value2: "value"})
      assert result ==  %{custom: %{key1: %{value1: "value"}, key2: %{value2: "value"}}}
    end

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

    test "multiple custom contexts get merged" do
      custom_context = %Timber.Contexts.CustomContext{type: "build", data: %{version: "1.0.0"}}
      context = Context.add(%{}, custom_context)
      assert context ==  %{custom: %{build: %{version: "1.0.0"}}}

      custom_context = %Timber.Contexts.CustomContext{type: "weather", data: %{forecast: "rainy"}}
      context = Context.add(context, custom_context)
      assert context ==  %{custom: %{build: %{version: "1.0.0"}, weather: %{forecast: "rainy"}}}
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

    test "system context with an integer pid" do
      user_context = %Timber.Contexts.SystemContext{pid: 1}
      result = Context.add(%{}, user_context)
      assert result ==  %{system: %{pid: 1}}
    end

    test "system context with a string ipd" do
      user_context = %Timber.Contexts.SystemContext{pid: "1"}
      result = Context.add(%{}, user_context)
      assert result ==  %{system: %{pid: 1}}
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

  describe "Timber.Context.merge/2" do
    test "merges with two custom contexts" do
      first_context = Context.add(%{}, %{build: %{version: "1.0.0"}})
      second_context = Context.add(%{}, %{build: %{timestamp: "1520867239"}})
      merged_context = Context.merge(first_context, second_context)

      custom_context = Map.get(merged_context, :custom)
      assert Map.has_key?(custom_context, :build)
      build = Map.get(custom_context, :build)
      assert Map.has_key?(build, :timestamp)
      refute Map.has_key?(build, :version)
    end

    test "merges with left-side custom context" do
      # this test makes sure that the left hand side custom context (the "first" context)
      # is preserved when there is no right hand side custom context
      first_context = Context.add(%{}, %{build: %{version: "1.0.0"}})
      second_context = %{}
      merged_context = Context.merge(first_context, second_context)

      custom_context = Map.get(merged_context, :custom)
      assert Map.has_key?(custom_context, :build)
      build = Map.get(custom_context, :build)
      assert Map.has_key?(build, :version)
    end
  end
end
