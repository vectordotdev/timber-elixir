defmodule Timber.EventableTest do
  use Timber.TestCase

  alias Timber.Events
  alias Timber.Eventable

  describe "Timber.Eventable.to_event/1" do
    #
    # Events
    #

    test "Timber.Events.ChannelJoinEvent" do
      base_event = %Events.ChannelJoinEvent{channel: "channel", topic: "topic"}
      event = Eventable.to_event(base_event)
      assert event == base_event
    end

    test "Timber.Events.ChannelReceiveEvent" do
      base_event = %Events.ChannelReceiveEvent{channel: "channel", topic: "topic", event: "event"}
      event = Eventable.to_event(base_event)
      assert event == base_event
    end

    #
    # Map
    #

    test "map with a single root key" do
      event = Eventable.to_event(%{build: %{version: "1.0.0"}})
      assert event == %Timber.Events.CustomEvent{data: %{version: "1.0.0"}, type: :build}
    end

    test "map with multiple root keys" do
      assert_raise FunctionClauseError, fn ->
        Eventable.to_event(%{build: %{version: "1.0.0"}, another: 1})
      end
    end

    test "structured map" do
      event = Eventable.to_event(%{type: :build, data: %{version: "1.0.0"}})
      assert event == %Timber.Events.CustomEvent{data: %{version: "1.0.0"}, type: :build}
    end

    #
    # Exception
    #

    test "exception" do
      error = %RuntimeError{message: "boom"}
      event = Eventable.to_event(error)
      assert event == %Timber.Events.ErrorEvent{name: "RuntimeError", message: "boom"}
    end
  end
end