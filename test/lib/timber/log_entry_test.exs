defmodule Timber.Events.LogEntryTest do
  use Timber.TestCase

  alias Timber.LogEntry

  describe "Timber.LogEntry.new/4" do
    test "success" do
      entry = LogEntry.new(time(), :info, "message", [event: %{type: :type, data: %{}}])
      assert entry == %Timber.LogEntry{context: %{system: %{hostname: hostname(), pid: "#{pid()}"}},
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

    test "adds exceptions" do
      log_message =
        """
        ** (exit) an exception was raised:
            ** (RuntimeError) boom
                (my_app) web/controllers/page_controller.ex:5: MyApp.PageController.index/2
                (my_app) web/controllers/page_controller.ex:1: MyApp.PageController.action/2
                (my_app) web/controllers/page_controller.ex:1: MyApp.PageController.phoenix_controller_pipeline/2
                (my_app) lib/my_app/endpoint.ex:1: MyApp.Endpoint.instrument/4
                (my_app) lib/phoenix/router.ex:261: MyApp.Router.dispatch/2
                (my_app) web/router.ex:1: MyApp.Router.do_call/2
                (my_app) lib/plug/error_handler.ex:64: MyApp.Router.call/2
                (my_app) lib/my_app/endpoint.ex:1: MyApp.Endpoint.phoenix_pipeline/1
                (my_app) lib/my_app/endpoint.ex:1: MyApp.Endpoint.call/2
                (plug) lib/plug/adapters/cowboy/handler.ex:15: Plug.Adapters.Cowboy.Handler.upgrade/4
                (cowboy) /Users/benjohnson/Code/timber/odin/deps/cowboy/src/cowboy_protocol.erl:442: :cowboy_protocol.execute/4
        """
      entry = LogEntry.new(time(), :info, log_message, [error_logger: true])
      assert entry.event.__struct__ == Timber.Events.ExceptionEvent
    end
  end

  describe "Timber.LogEntry.to_string!/3" do
    test "drops blanks" do
      entry = LogEntry.new(time(), :info, "message", [event: %{type: :type, data: %{}}])
      result = LogEntry.to_string!(entry, :json)
      assert String.Chars.to_string(result) == "{\"message\":\"message\",\"level\":\"info\",\"dt\":\"2016-01-21T12:54:56.001234Z\",\"context\":{\"system\":{\"pid\":\"#{pid()}\",\"hostname\":\"#{hostname()}\"}},\"$schema\":\"https://raw.githubusercontent.com/timberio/log-event-json-schema/1.2.21/schema.json\"}"
    end

    test "encodes JSON properly" do
      entry = LogEntry.new(time(), :info, "message", [event: %{type: :type, data: %{test: "value"}}])
      result = LogEntry.to_string!(entry, :json)
      assert String.Chars.to_string(result) == "{\"message\":\"message\",\"level\":\"info\",\"event\":{\"custom\":{\"type\":{\"test\":\"value\"}}},\"dt\":\"2016-01-21T12:54:56.001234Z\",\"context\":{\"system\":{\"pid\":\"#{pid()}\",\"hostname\":\"#{hostname()}\"}},\"$schema\":\"https://raw.githubusercontent.com/timberio/log-event-json-schema/1.2.21/schema.json\"}"
    end

    test "encodes logfmt properly" do
      entry = LogEntry.new(time(), :info, "message", [event: %{type: :type, data: %{a: 1}}])
      result = LogEntry.to_string!(entry, :logfmt)
      assert result == [[10, 9, "Context: ", ["system.pid", 61, "#{pid()}", 32, "system.hostname", 61, "#{hostname()}"]], [10, 9, "Event: ", ["custom.type.a", 61, "1"]]]
    end
  end

  defp hostname do
    case :inet.gethostname() do
      {:ok, hostname} -> to_string(hostname)
      _else -> nil
    end
  end
  defp pid do
    System.get_pid()
  end

  defp time do
    {{2016, 1, 21}, {12, 54, 56, {1234, 4}}}
  end
end