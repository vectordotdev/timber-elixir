defmodule Timber.Events.HTTPClientRequestEventTest do
  use Timber.TestCase
  doctest Timber.Events.HTTPClientRequestEvent

  alias Timber.Events.HTTPClientRequestEvent

  describe "Timber.Events.HTTPClientRequestEvent.new/1" do
    test "normalizes headers from a list" do
      headers = [{"x-request-id", "value"}, {"user-agent", "agent"}]
      result = HTTPClientRequestEvent.new(headers: headers, host: "host", method: :get, path: "path", port: 12, scheme: "https")
      assert result.headers == %{request_id: "value", user_agent: "agent"}
    end

    test "filters headers" do
      headers = [{"x-request-id", "value"}, {"user-agent", "agent"}, {"random-header", "value"}]
      result = HTTPClientRequestEvent.new(headers: headers, host: "host", method: :get, path: "path", port: 12, scheme: "https")
      assert result.headers == %{request_id: "value", user_agent: "agent"}
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
end