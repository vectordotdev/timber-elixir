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

    test "adds tags" do
      entry = LogEntry.new(time(), :info, "message", [tags: ["tag1", "tag2"]])
      assert entry.tags == ["tag1", "tag2"]
    end

    test "adds time_ms" do
      entry = LogEntry.new(time(), :info, "message", [time_ms: 56.4])
      assert entry.time_ms == 56.4
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
      assert String.Chars.to_string(result) == "{\"message\":\"message\",\"level\":\"info\",\"event\":{\"custom\":{\"type\":{\"test\":\"value\"}}},\"dt\":\"2016-01-21T12:54:56.001234Z\",\"context\":{\"system\":{\"pid\":\"#{System.get_pid()}\"}},\"$schema\":\"#{LogEntry.schema()}\"}"
    end

    test "encodes logfmt properly" do
      entry = LogEntry.new(time(), :info, "message", [event: %{type: :type, data: %{a: 1}}])
      result = LogEntry.to_string!(entry, :logfmt)
      assert result == [[10, 9, "Context: ", ["system.pid", 61, "#{System.get_pid()}"]], [10, 9, "Event: ", ["custom.type.a", 61, "1"]]]
    end
  end

  defp time do
    {{2016, 1, 21}, {12, 54, 56, {1234, 4}}}
  end
end