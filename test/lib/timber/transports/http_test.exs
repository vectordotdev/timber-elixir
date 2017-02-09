defmodule Timber.Transports.HTTPTest do
  use Timber.TestCase

  alias Timber.FakeHTTPClient
  alias Timber.LogEntry
  alias Timber.Transports.HTTP

  describe "Timber.Transports.HTTP.init/0" do
    test "starts the flusher" do
      HTTP.init()
      assert_receive(:flusher_step, 1100)
    end
  end

  describe "Timber.Transports.HTTP.write/0" do
    test "buffers the message" do
      entry = LogEntry.new(time(), :info, "message", [event: %{type: :type, data: %{}}])
      {:ok, state} = HTTP.init()
      {:ok, new_state} = HTTP.write(entry, state)
      assert new_state.buffer == [entry]
      calls = FakeHTTPClient.get_request_calls()
      assert length(calls) == 0
    end

    test "issues a HTTP request" do
      entry = LogEntry.new(time(), :info, "message", [event: %{type: :type, data: %{}}])
      {:ok, state} = HTTP.init()
      state = %{state | max_buffer_size: 0}
      HTTP.write(entry, state)
      calls = FakeHTTPClient.get_request_calls()
      assert length(calls) == 1
      call = Enum.at(calls, 0)
      assert elem(call, 0) == :post
      assert elem(call, 1) == "https://api.timber.io/frames"
      assert elem(call, 2) == %{"Authorization" => "Basic YXBpX2tleQ==", "Content-Type" => "application/msgpack", "User-Agent" => "Timber Elixir HTTP Transport/1.0.0"}
      {:ok, encoded_body} = Msgpax.pack([LogEntry.to_map!(entry)])
      assert elem(call, 3) == encoded_body
      assert elem(call, 4) == []
    end
  end

  defp time do
    {{2016, 1, 21}, {12, 54, 56, {1234, 4}}}
  end
end