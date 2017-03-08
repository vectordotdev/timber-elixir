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

    test "authorization header" do
      assert HTTPEvents.normalize_headers([{"Authorization", "value"}]) == %{"authorization" => "[sanitized]"}
    end

    test "headers list" do
      assert HTTPEvents.normalize_headers([{"This-IS-my-HEADER", "value"}]) == %{"this-is-my-header" => "value"}
    end
  end
end