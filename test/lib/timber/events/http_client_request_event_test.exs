defmodule Timber.Events.HTTPClientRequestEventTest do
  use Timber.TestCase
  doctest Timber.Events.HTTPClientRequestEvent

  alias Timber.Events.HTTPClientRequestEvent

  describe "Timber.Events.HTTPClientRequestEvent.new/1" do
    test "normalizes headers from a list" do
      headers = [{"x-request-id", "value"}, {"user-agent", "agent"}]
      result = HTTPClientRequestEvent.new(headers: headers, host: "host", method: :get, path: "path", port: 12, scheme: "https")
      assert result.headers == %{"user-agent" => "agent", "x-request-id" => "value"}
    end

    test "filters headers" do
      headers = [{"x-request-id", "value"}, {"user-agent", "agent"}, {"random-header", "value"}]
      result = HTTPClientRequestEvent.new(headers: headers, host: "host", method: :get, path: "path", port: 12, scheme: "https")
      assert result.headers == %{"random-header" => "value", "user-agent" => "agent", "x-request-id" => "value"}
    end

    test "normalizes method" do
      result = HTTPClientRequestEvent.new(host: "host", method: :get, path: "path", port: 12, scheme: "https")
      assert result.method == "GET"
    end

    test "expands a url" do
      result = HTTPClientRequestEvent.new(method: :get, url: "https://timber.io/path?query")
      assert result.host == "timber.io"
      assert result.path == "/path"
      assert result.port == 443
      assert result.query_string == "query"
      assert result.scheme == "https"
    end
  end

  describe "Timber.Events.HTTPClientRequestEvent.message/1" do
    test "includes service name and query string" do
      headers = [{"user-agent", "agent"}]
      event = HTTPClientRequestEvent.new(headers: headers, host: "host", method: :get,
        path: "path", port: 12, query_string: "query", scheme: "https", service_name: :service)
      message = HTTPClientRequestEvent.message(event)
      assert String.Chars.to_string(message) == "Outgoing HTTP request to service [GET] path?query"
    end

    test "service name excluded" do
      headers = [{"user-agent", "agent"}]
      event = HTTPClientRequestEvent.new(headers: headers, host: "host", method: :get,
        path: "path", port: 12, query_string: "query", scheme: "https")
      message = HTTPClientRequestEvent.message(event)
      assert String.Chars.to_string(message) == "Outgoing HTTP request to [GET] https://host:12path?query"
    end
  end
end