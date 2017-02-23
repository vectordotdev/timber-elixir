defmodule Timber.EventTest do
  use Timber.TestCase

  alias Timber.Event

  describe "Timber.Event.to_api_map/2" do
    test "custom event with a string type" do
      custom_event = %Timber.Events.CustomEvent{type: "build", data: %{version: "1.0.0"}}
      map = Event.to_api_map(custom_event)
      assert map == %{custom: %{build: %{version: "1.0.0"}}}
    end
  end
end