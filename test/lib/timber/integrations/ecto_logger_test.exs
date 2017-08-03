if Code.ensure_loaded?(Ecto) do
  defmodule Timber.Integrations.EctoLoggerTest do
    use Timber.TestCase

    import ExUnit.CaptureLog

    alias Timber.Integrations.EctoLogger

    require Logger

    describe "Timber.Integrations.EctoLogger.log/2" do
      test "exceeds the query threshold" do
        query = "SELECT * FROM table"
        timer = 0

        log = capture_log(fn ->
          EctoLogger.log(%{query: query, query_time: timer}, :info)
        end)

        assert log =~ "Processed SELECT * FROM table in"
        assert log =~ " @metadata "
      end
    end
  end
end