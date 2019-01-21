defmodule Timber.Events.ErrorEventTest do
  defmodule CustomError do
    defexception [:message, :key]
  end

  use Timber.TestCase

  alias Timber.Events.ErrorEvent

  describe "Timber.Events.ErrorEvent.from_exception/1" do
    test "builds an error event" do
      error = %CustomError{message: "message", key: "value"}
      event = ErrorEvent.from_exception(error)

      assert event == %ErrorEvent{
               backtrace: nil,
               message: "message",
               metadata_json: "{\"key\":\"value\"}",
               name: "Timber.Events.ErrorEventTest.CustomError"
             }
    end
  end
end
