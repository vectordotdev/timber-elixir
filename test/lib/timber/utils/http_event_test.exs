defmodule Timber.Utils.HTTPEventsTest do
  use Timber.TestCase

  alias Timber.Utils.HTTPEvents

  describe "Timber.Utils.HTTPEvents.normalize_body/1" do
    test "nil" do
      assert HTTPEvents.normalize_body(nil) == nil
    end

    test "blank string" do
      assert HTTPEvents.normalize_body("") == ""
    end

    test "blank map" do
      assert HTTPEvents.normalize_body(%{}) == nil
    end

    test "blank list" do
      assert HTTPEvents.normalize_body([]) == ""
    end

    test "iodata" do
      assert HTTPEvents.normalize_body(["a", "b", ["c", "d"]]) == "abcd"
    end

    test "exceeds length" do
      body = String.duplicate("a", 20001)
      assert HTTPEvents.normalize_body(body) == [String.duplicate("a", 1985), " (truncated)"]
    end
  end

  describe "Timber.Utils.HTTPEvents.normalize_headers/1" do
    test "nil" do
      assert HTTPEvents.normalize_headers(nil) == nil
    end

    test "blank map" do
      assert HTTPEvents.normalize_headers(%{}) == %{}
    end

    test "real map" do
      assert HTTPEvents.normalize_headers(%{"key" => "value"}) == %{"key" => "value"}
    end

    test "blank list" do
      assert HTTPEvents.normalize_headers([]) == %{}
    end

    test "array value" do
      assert HTTPEvents.normalize_headers([{"key", ["value1", "value2"]}]) == %{"key" => "value1,value2"}
    end

    test "authorization header" do
      assert HTTPEvents.normalize_headers([{"Authorization", "value"}]) == %{"authorization" => "[sanitized]"}
    end

    test "x-amz-security-token header" do
      assert HTTPEvents.normalize_headers([{"x-amz-security-token", "value"}]) == %{"x-amz-security-token" => "[sanitized]"}
    end

    test "custom sensitive header" do
      assert HTTPEvents.normalize_headers([{"Sensitive-Key", "value"}]) == %{"sensitive-key" => "[sanitized]"}
    end

    test "headers list" do
      assert HTTPEvents.normalize_headers([{"This-IS-my-HEADER", "value"}]) == %{"this-is-my-header" => "value"}
    end
  end
end