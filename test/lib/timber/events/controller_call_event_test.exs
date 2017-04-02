defmodule Timber.Events.ControllerCallEventTest do
  use Timber.TestCase

  alias Timber.Events.ControllerCallEvent

  describe "Timber.Events.ControllerCallEvent.new/1" do
    test "converts params to params_json" do
      event = ControllerCallEvent.new(action: "action", controller: "controller", params: %{key: "value"}, pipelines: [1])
      assert event == %ControllerCallEvent{action: "action", controller: "controller", params_json: "{\"key\":\"value\"}", pipelines: [1]}
    end
  end
end