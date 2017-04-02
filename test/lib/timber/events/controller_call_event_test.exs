defmodule Timber.Events.ControllerCallEventTest do
  use Timber.TestCase

  alias Timber.Events.ControllerCallEvent

  describe "Timber.Events.ControllerCallEvent.new/1" do
    test "converts params to params_json" do
      event = ControllerCallEvent.new(action: "action", controller: "controller", params: %{key: "value"}, pipelines: [1])
      assert event == %ControllerCallEvent{action: "action", controller: "controller", params_json: [123, [[34, ["key"], 34], 58, [34, ["value"], 34]], 125], pipelines: [1]}
    end

    test "ignores blank params maps" do
      event = ControllerCallEvent.new(action: "action", controller: "controller", params: %{}, pipelines: [1])
      assert event == %ControllerCallEvent{action: "action", controller: "controller", params_json: nil, pipelines: [1]}
    end
  end

  describe "Timber.Events.ControllerCallEvent.message/1" do
    test "default message" do
      event = ControllerCallEvent.new(action: "action", controller: "controller", params: %{}, pipelines: [1])
      message = ControllerCallEvent.message(event)
      assert message == ["Processing with ", "controller", 46, "action", 47, 50, " Pipelines: ", "[1]"]
    end
  end
end