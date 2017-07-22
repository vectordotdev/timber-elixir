defmodule Timber.Events.HTTPRequestEventTest do
  use Timber.TestCase

  alias Timber.Events.HTTPRequestEvent

  describe "Timber.Events.HTTPRequestEvent.new/1" do
    test "normalizes headers from a list" do
      headers = [{"x-request-id", "value"}, {"user-agent", "agent"}]
      result = HTTPRequestEvent.new(headers: headers, host: "host", method: :get, path: "path", port: 12, scheme: "https")
      assert result.headers == nil
      assert result.headers_json == "{\"x-request-id\":\"value\",\"user-agent\":\"agent\"}"
    end

    test "filters headers" do
      headers = [{"x-request-id", "value"}, {"user-agent", "agent"}, {"random-header", "value"}]
      result = HTTPRequestEvent.new(headers: headers, host: "host", method: :get, path: "path", port: 12, scheme: "https")
      assert result.headers == nil
      assert result.headers_json == "{\"x-request-id\":\"value\",\"user-agent\":\"agent\",\"random-header\":\"value\"}"
    end

    test "deletes body" do
      result = HTTPRequestEvent.new(body: String.duplicate("a", 2001), host: "host", method: :get, path: "path", port: 12, scheme: "https")
      assert result.body == nil
    end

    test "normalizes method" do
      result = HTTPRequestEvent.new(host: "host", method: :get, path: "path", port: 12, scheme: "https")
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
      event = HTTPRequestEvent.new(direction: "outgoing", headers: headers, host: "host", method: :get,
        path: "path", port: 12, query_string: "query", request_id: "abcd1234", scheme: "https", service_name: "service")
      message = HTTPRequestEvent.message(event)
      assert String.Chars.to_string(message) == "Sent GET https://host:12path?query (abcd12...) to service"
    end

    test "outgoing, service name excluded" do
      headers = [{"user-agent", "agent"}]
      event = HTTPRequestEvent.new(direction: "outgoing", headers: headers, host: "host", method: :get,
        path: "path", port: 12, query_string: "query", scheme: "https")
      message = HTTPRequestEvent.message(event)
      assert String.Chars.to_string(message) == "Sent GET https://host:12path?query"
    end
  end
end