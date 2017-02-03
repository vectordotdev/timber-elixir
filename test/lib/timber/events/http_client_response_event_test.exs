defmodule Timber.Events.HTTPClientResponseEventTest do
  use Timber.TestCase

  alias Timber.Events.HTTPClientResponseEvent

  describe "Timber.Events.HTTPClientResponseEvent.new/1" do
    test "normalizes headers from a list" do
      headers = [{"x-request-id", "value"}, {"content_type", "type"}]
      result = HTTPClientResponseEvent.new(headers: headers, status: 200, time_ms: 502)
      assert result.headers == %{request_id: "value", content_type: "type"}
    end

    test "filters headers" do
      headers = [{"x-request-id", "value"}, {"content_type", "type"}, {"random-header", "value"}]
      result = HTTPClientResponseEvent.new(headers: headers, status: 200, time_ms: 502)
      assert result.headers == %{request_id: "value", content_type: "type"}
    end
  end
end