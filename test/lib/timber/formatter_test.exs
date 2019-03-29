defmodule Timber.FormatterTest do
  use Timber.TestCase

  import ExUnit.CaptureLog

  require Logger

  describe "Timber.Formatter.format/4" do
    test "includes runtime metadata" do
      log_output =
        capture_log(fn ->
          Logger.error("log message")
        end)

      map = Jason.decode!(log_output)

      assert map["context"]["runtime"]
      assert map["message"] == "log message"
    end
  end
end
