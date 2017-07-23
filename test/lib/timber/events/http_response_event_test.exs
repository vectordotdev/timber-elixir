defmodule Timber.Events.HTTPResponseEventTest do
  use Timber.TestCase

  alias Timber.Events.HTTPResponseEvent

  describe "Timber.Events.HTTPResponseEvent.new/1" do
    test "normalizes headers from a list" do
      headers = [{"x-request-id", "value"}, {"content_type", "type"}]
      result = HTTPResponseEvent.new(headers: headers, status: 200, time_ms: 502)
      assert result.headers == nil
      assert result.headers_json == "{\"x-request-id\":\"value\",\"content_type\":\"type\"}"
    end

    test "filters headers" do
      headers = [{"x-request-id", "value"}, {"content_type", "type"}, {"random-header", "value"}]
      result = HTTPResponseEvent.new(headers: headers, status: 200, time_ms: 502)
      assert result.headers == nil
      assert result.headers_json == "{\"x-request-id\":\"value\",\"random-header\":\"value\",\"content_type\":\"type\"}"
    end

    test "truncates body" do
      result = HTTPResponseEvent.new(body: String.duplicate("a", 2049), status: 200, time_ms: 52)
      assert result.body == String.duplicate("a", 2033) <> " (truncated)"
    end
  end

  describe "Timber.Events.HTTPResponseEvent.message/1" do
    test "incoming, includes the service name" do
      event = HTTPResponseEvent.new(direction: "incoming", request_id: "abcd1234", service_name: "timber", status: 200, time_ms: 502.2)
      message = HTTPResponseEvent.message(event)
      assert String.Chars.to_string(message) == "Received 200 response (abcd12...) from timber in 502.20ms"
    end

    test "incoming, integer time_ms" do
      event = HTTPResponseEvent.new(direction: "incoming", status: 200, time_ms: 1)
      message = HTTPResponseEvent.message(event)
      assert String.Chars.to_string(message) == "Received 200 response in 1ms"
    end

    test "incoming, nanoseconds time_ms" do
      event = HTTPResponseEvent.new(direction: "incoming", status: 200, time_ms: 0.56)
      message = HTTPResponseEvent.message(event)
      assert String.Chars.to_string(message) == "Received 200 response in 560µs"
    end
  end
end