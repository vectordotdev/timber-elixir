defmodule Timber.Events.LogEntryTest do
  use Timber.TestCase

  alias Timber.LogEntry

  describe "Timber.LogEntry.new/4" do
    test "success" do
      entry = LogEntry.new(time(), :info, "message", [event: %{type: :type, data: %{}}])
      assert entry == %Timber.LogEntry{context: %{system: %{pid: "#{System.get_pid()}"}},
         dt: "2016-01-21T12:54:56.001234Z",
         event: %Timber.Events.CustomEvent{data: %{}, type: :type},
         level: :info, message: "message"}
    end
  end

  describe "Timber.LogEntry.to_string!/3" do
    test "drops blanks" do
      entry = LogEntry.new(time(), :info, "message", [event: %{type: :type, data: %{}}])
      result = LogEntry.to_string!(entry, :json)
      assert String.Chars.to_string(result) == "{\"message\":\"message\",\"level\":\"info\",\"dt\":\"2016-01-21T12:54:56.001234Z\",\"context\":{\"system\":{\"pid\":\"#{System.get_pid()}\"}},\"$schema\":\"#{LogEntry.schema()}\"}"
    end

    test "encodes JSON properly" do
      entry = LogEntry.new(time(), :info, "message", [event: %{type: :type, data: %{test: "value"}}])
      result = LogEntry.to_string!(entry, :json)
      assert String.Chars.to_string(result) == "{\"message\":\"message\",\"level\":\"info\",\"event\":{\"server_side_app\":{\"custom\":{\"type\":{\"test\":\"value\"}}}},\"dt\":\"2016-01-21T12:54:56.001234Z\",\"context\":{\"system\":{\"pid\":\"#{System.get_pid()}\"}},\"$schema\":\"#{LogEntry.schema()}\"}"
    end

    test "encodes logfmt properly" do
      entry = LogEntry.new(time(), :info, "message", [event: %{type: :type, data: %{a: 1}}])
      result = LogEntry.to_string!(entry, :logfmt)
      assert result == [[10, 9, "Context: ", ["system.pid", 61, "#{System.get_pid()}"]], [10, 9, "Event: ", ["server_side_app.custom.type.a", 61, "1"]]]
    end
  end

  defp time do
    {{2016, 1, 21}, {12, 54, 56, {1234, 4}}}
  end
end