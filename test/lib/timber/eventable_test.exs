defmodule Timber.EventableTest do
  use Timber.TestCase

  alias Timber.Eventable

  describe "Timber.Eventable.to_event/1" do
    test "map with a single root key" do
      map = %{order_placed: %{total: 100}}
      event = Eventable.to_event(map)
      assert event == map
    end

    test "map with multiple root keys" do
      Eventable.to_event(%{build: %{version: "1.0.0"}, another: 1})
    end

    test "structured map" do
      map = %{type: :order_placed, data: %{total: 100}}
      event = Eventable.to_event(map)
      assert event == %{order_placed: %{total: 100}}
    end

    test "exception" do
      error = %RuntimeError{message: "boom"}
      event = Eventable.to_event(error)

      assert event == %{
               error: %{
                 backtrace: nil,
                 message: "boom",
                 metadata_json: nil,
                 name: "RuntimeError"
               }
             }
    end
  end
end
