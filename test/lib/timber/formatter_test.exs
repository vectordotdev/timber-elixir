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

      assert log_output =~ " @metadata "
    end
  end
end
