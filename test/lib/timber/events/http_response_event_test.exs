defmodule Timber.Events.HTTPResponseEventTest do
  use Timber.TestCase

  alias Timber.Events.HTTPResponseEvent

  describe "Timber.Events.HTTPResponseEvent.new/1" do
    test "normalizes headers from a list" do
      request_id = "value"
      content_type = "type"
      headers = [{"x-request-id", request_id}, {"content-type", content_type}]
      result = HTTPResponseEvent.new(headers: headers, status: 200, time_ms: 502)
      assert result.headers == nil

      headers_json = Jason.decode!(result.headers_json)

      assert Map.fetch!(headers_json, "x-request-id") == request_id
      assert Map.fetch!(headers_json, "content-type") == content_type
    end

    test "filters headers" do
      request_id = "value"
      content_type = "type"
      random_header = "value"

      headers = [
        {"x-request-id", request_id},
        {"content-type", content_type},
        {"random-header", random_header}
      ]

      result = HTTPResponseEvent.new(headers: headers, status: 200, time_ms: 502)

      assert result.headers == nil

      headers_json = Jason.decode!(result.headers_json)

      assert Map.fetch!(headers_json, "x-request-id") == request_id
      assert Map.fetch!(headers_json, "content-type") == content_type
      assert Map.fetch!(headers_json, "random-header") == random_header
    end

    test "truncates body" do
      result = HTTPResponseEvent.new(body: String.duplicate("a", 2049), status: 200, time_ms: 52)
      assert result.body == String.duplicate("a", 2033) <> " (truncated)"
    end
  end

  describe "Timber.Events.HTTPResponseEvent.message/1" do
    test "incoming, includes the service name" do
      event =
        HTTPResponseEvent.new(
          direction: "incoming",
          request_id: "abcd1234",
          service_name: "timber",
          status: 200,
          time_ms: 502.2
        )

      message = HTTPResponseEvent.message(event)

      assert String.Chars.to_string(message) ==
               "Received 200 response (abcd12...) from timber in 502.20ms"
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
