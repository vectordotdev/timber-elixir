if Code.ensure_loaded?(Phoenix) do
  defmodule Timber.Integrations.PhoenixInstrumenterTest do
    use Timber.TestCase

    import ExUnit.CaptureLog

    alias Timber.Integrations.PhoenixInstrumenter

    require Logger

    describe "Timber.Integrations.PhoenixInstrumenter.phoenix_channel_join/3" do
      test "logs phoenix_channel_join as configured by the channel" do
        log = capture_log(fn ->
          socket = %Phoenix.Socket{channel: :channel, topic: "topic"}
          PhoenixInstrumenter.phoenix_channel_join(:start, %{}, %{socket: socket, params: %{key: "val"}})
        end)
        assert log =~ "Joined channel channel with \"topic\" @metadata "
      end
    end

    describe "Timber.Integrations.PhoenixInstrumenter.phoenix_channel_receive/3" do
      test "logs phoenix_channel_receive as configured by the channel" do
        log = capture_log(fn ->
          socket = %Phoenix.Socket{channel: :channel, topic: "topic"}
          PhoenixInstrumenter.phoenix_channel_receive(:start, %{}, %{socket: socket, event: "e", params: %{}})
        end)
        assert log =~ "Received e on \"topic\" to channel @metadata "
      end
    end
  end
end