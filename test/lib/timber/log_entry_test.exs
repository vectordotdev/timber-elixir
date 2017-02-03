defmodule Timber.Events.LogEntryTest do
  use Timber.TestCase

  alias Timber.LogEntry

  describe "Timber.LogEntry.new/4" do
    test "success" do
      time = {{2016, 1, 21}, {12, 54, 56, {1234, 4}}}
      result = LogEntry.new(time, :info, "message", [event: %{type: :type, data: %{}}])
      assert result == %Timber.LogEntry{context: %{}, dt: "2016-01-21T12:54:56.001234Z",
         event: %Timber.Events.CustomEvent{data: %{}, type: :type},
         level: :info, message: "message"}
    end
  end
end