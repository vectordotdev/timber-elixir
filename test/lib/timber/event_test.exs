defmodule Timber.EventTest do
  use Timber.TestCase

  alias Timber.Event

  describe "Timber.Event.to_api_map/2" do
    test "custom event with a string type" do
      custom_event = %Timber.Events.CustomEvent{type: "build", data: %{version: "1.0.0"}}
      map = Event.to_api_map(custom_event)
      assert map == %{custom: %{build: %{version: "1.0.0"}}}
    end

    test "controller call event" do
      event = %Timber.Events.ControllerCallEvent{action: "action", controller: "controller", params_json: "{\"key\": \"value\"}", pipelines: [1]}
      map = Event.to_api_map(event)
      assert map == %{server_side_app: %{controller_call: %{action: "action", controller: "controller", params_json: "{\"key\": \"value\"}"}}}
    end
  end
end