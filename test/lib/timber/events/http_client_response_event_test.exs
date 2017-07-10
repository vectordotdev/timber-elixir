defmodule Timber.Events.HTTPClientResponseEventTest do
  use Timber.TestCase

  alias Timber.Events.HTTPClientResponseEvent

  describe "Timber.Events.HTTPClientResponseEvent.new/1" do
    test "normalizes headers from a list" do
      headers = [{"x-request-id", "value"}, {"content_type", "type"}]
      result = HTTPClientResponseEvent.new(headers: headers, status: 200, time_ms: 502)
      assert result.headers == nil
      assert result.headers_json == "{\"x-request-id\":\"value\",\"content_type\":\"type\"}"
    end

    test "filters headers" do
      headers = [{"x-request-id", "value"}, {"content_type", "type"}, {"random-header", "value"}]
      result = HTTPClientResponseEvent.new(headers: headers, status: 200, time_ms: 502)
      assert result.headers == nil
      assert result.headers_json == "{\"x-request-id\":\"value\",\"random-header\":\"value\",\"content_type\":\"type\"}"
    end
  end

  describe "Timber.Events.HTTPClientResponseEvent.message/1" do
    test "includes the service name" do
      event = HTTPClientResponseEvent.new(request_id: "abcd1234", service_name: "timber", status: 200, time_ms: 502.2)
      message = HTTPClientResponseEvent.message(event)
      assert String.Chars.to_string(message) == "Outgoing HTTP response (abcd12...) from timber 200 in 502.20ms"
    end

    test "integer time_ms" do
      event = HTTPClientResponseEvent.new(status: 200, time_ms: 1)
      message = HTTPClientResponseEvent.message(event)
      assert String.Chars.to_string(message) == "Outgoing HTTP response 200 in 1ms"
    end

    test "nanoseconds time_ms" do
      event = HTTPClientResponseEvent.new(status: 200, time_ms: 0.56)
      message = HTTPClientResponseEvent.message(event)
      assert String.Chars.to_string(message) == "Outgoing HTTP response 200 in 560µs"
    end
  end
end