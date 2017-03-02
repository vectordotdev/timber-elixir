defmodule Timber.Transports.IODeviceTest do
  use Timber.TestCase

  alias Timber.LogEntry
  alias Timber.Transports.IODevice

  describe "Timber.Transports.IODevice.write/2" do
    test "escapes lines in metadata when enabled" do
      {:ok, state} = IODevice.init()

      {:ok, device} = StringIO.open("")
      {:ok, state} = IODevice.configure([device: device, escape_new_lines: true], state)

      entry = LogEntry.new(time(), :info, "message", [event: %{type: :type, data: %{test: "new\nline"}}])
      {:ok, _state} = IODevice.write(entry, state)

      message = StringIO.flush(device)
      assert message =~ "{\"test\":\"new\\nline\"}"
    end
  end

  defp time do
    {{2016, 1, 21}, {12, 54, 56, {1234, 4}}}
  end
end