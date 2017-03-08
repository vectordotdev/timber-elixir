defmodule Timber.Events.HTTPServerRequestEventTest do
  use Timber.TestCase

  alias Timber.Events.HTTPServerRequestEvent

  describe "Timber.Events.HTTPServerRequestEvent.new/1" do
    test "normalizes headers from a list" do
      headers = [{"x-request-id", "value"}, {"user-agent", "agent"}]
      result = HTTPServerRequestEvent.new(headers: headers, host: "host", method: :get, path: "path", port: 12, scheme: "https")
      assert result.headers == %{"user-agent" => "agent", "x-request-id" => "value"}
    end

    test "filters headers" do
      headers = [{"x-request-id", "value"}, {"user-agent", "agent"}, {"random-header", "value"}]
      result = HTTPServerRequestEvent.new(headers: headers, host: "host", method: :get, path: "path", port: 12, scheme: "https")
      assert result.headers == %{"random-header" => "value", "user-agent" => "agent", "x-request-id" => "value"}
    end

    test "normalizes method" do
      result = HTTPServerRequestEvent.new(host: "host", method: :get, path: "path", port: 12, scheme: "https")
      assert result.method == "GET"
    end

    test "expands a url" do
      result = HTTPServerRequestEvent.new(method: :get, url: "https://timber.io/path?query")
      assert result.host == "timber.io"
      assert result.path == "/path"
      assert result.port == 443
      assert result.query_string == "query"
      assert result.scheme == "https"
    end
  end
end