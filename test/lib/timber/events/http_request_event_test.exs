defmodule Timber.Events.HTTPRequestEventTest do
  use Timber.TestCase

  alias Timber.Events.HTTPRequestEvent

  describe "Timber.Events.HTTPRequestEvent.new/1" do
    test "normalizes headers from a list" do
      request_id = "value"
      user_agent = "agent"
      headers = [{"x-request-id", request_id}, {"user-agent", user_agent}]

      result =
        HTTPRequestEvent.new(
          headers: headers,
          host: "host",
          method: :get,
          path: "path",
          port: 12,
          scheme: "https"
        )

      assert result.headers == nil
      headers_json = Jason.decode!(result.headers_json)

      assert Map.fetch!(headers_json, "x-request-id") == request_id
      assert Map.fetch!(headers_json, "user-agent") == user_agent
    end

    test "filters headers" do
      request_id = "value"
      user_agent = "agent"
      random_header = "value"

      headers = [
        {"x-request-id", request_id},
        {"user-agent", user_agent},
        {"random-header", random_header}
      ]

      result =
        HTTPRequestEvent.new(
          headers: headers,
          host: "host",
          method: :get,
          path: "path",
          port: 12,
          scheme: "https"
        )

      assert result.headers == nil

      headers_json = Jason.decode!(result.headers_json)

      assert Map.fetch!(headers_json, "x-request-id") == request_id
      assert Map.fetch!(headers_json, "user-agent") == user_agent
    end

    test "truncates body" do
      result =
        HTTPRequestEvent.new(
          body: String.duplicate("a", 2049),
          host: "host",
          method: :get,
          path: "path",
          port: 12,
          scheme: "https"
        )

      assert result.body == String.duplicate("a", 2033) <> " (truncated)"
    end

    test "normalizes method" do
      result =
        HTTPRequestEvent.new(host: "host", method: :get, path: "path", port: 12, scheme: "https")

      assert result.method == "GET"
    end

    test "expands a full url" do
      result = HTTPRequestEvent.new(method: :get, url: "https://timber.io/path?query")
      assert result.host == "timber.io"
      assert result.path == "/path"
      assert result.port == 443
      assert result.query_string == "query"
      assert result.scheme == "https"
    end

    test "expands a url with just a host" do
      result = HTTPRequestEvent.new(method: :get, url: "https://timber.io")
      assert result.host == "timber.io"
      assert result.path == nil
      assert result.port == 443
      assert result.query_string == nil
      assert result.scheme == "https"
    end
  end

  describe "Timber.Events.HTTPRequestEvent.message/1" do
    test "outgoing, service name and query string" do
      headers = [{"user-agent", "agent"}, {"x-request-id", "abcd1234"}]

      event =
        HTTPRequestEvent.new(
          direction: "outgoing",
          headers: headers,
          host: "host",
          method: :get,
          path: "/path",
          port: 12,
          query_string: "query",
          request_id: "abcd1234",
          scheme: "https",
          service_name: "service"
        )

      message = HTTPRequestEvent.message(event)
      assert String.Chars.to_string(message) == "Sent GET /path (abcd12...) to service"
    end

    test "outgoing, service name excluded" do
      headers = [{"user-agent", "agent"}]

      event =
        HTTPRequestEvent.new(
          direction: "outgoing",
          headers: headers,
          host: "host",
          method: :get,
          path: "path",
          port: 12,
          query_string: "query",
          scheme: "https"
        )

      message = HTTPRequestEvent.message(event)
      assert String.Chars.to_string(message) == "Sent GET https://host:12path?query"
    end
  end
end
