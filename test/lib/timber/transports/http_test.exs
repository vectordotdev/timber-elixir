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

  describe "Timber.Transports.HTTP.configure/2" do
    test "requiers an API key" do
      {:ok, state} = HTTP.init()
      result = HTTP.configure([api_key: nil], state)
      assert result == {:error, :no_api_key}
    end

    test "updates the api key" do
      {:ok, state} = HTTP.init()
      {:ok, new_state} = HTTP.configure([api_key: "new_api_key"], state)
      assert new_state.api_key == "new_api_key"
    end

    test "updates the max_buffer_size" do
      {:ok, state} = HTTP.init()
      {:ok, new_state} = HTTP.configure([max_buffer_size: 100], state)
      assert new_state.max_buffer_size == 100
    end
  end

  describe "Timber.Transports.HTTP.flush/0" do
    test "does nothing when the buffer is empty" do
      {:ok, state} = HTTP.init()
      new_state = HTTP.flush(state)
      assert state == new_state
      calls = FakeHTTPClient.get_request_calls()
      assert length(calls) == 0
    end
  end

  describe "Timber.Transports.HTTP.handle_info/2" do
    test "handles the flusher_step properly" do
      entry = LogEntry.new(time(), :info, "message", [event: %{type: :type, data: %{}}])
      {:ok, state} = HTTP.init()
      {:ok, state} = HTTP.write(entry, state)
      {:ok, new_state} = HTTP.handle_info(:flusher_step, state)
      calls = FakeHTTPClient.get_request_calls()
      assert length(calls) == 1
      assert length(new_state.buffer) == 0
      assert_receive(:flusher_step, 1100)
    end

    test "ignores everything else" do
      {:ok, state} = HTTP.init()
      {:ok, new_state} = HTTP.handle_info(:unknown, state)
      assert state == new_state
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
      vsn = Application.spec(:timber, :vsn)
      assert elem(call, 2) == %{"Authorization" => "Basic YXBpX2tleQ==", "Content-Type" => "application/msgpack", "User-Agent" => "Timber Elixir/#{vsn} (HTTP)"}
      {:ok, encoded_body} = Msgpax.pack([LogEntry.to_map!(entry)])
      assert elem(call, 3) == encoded_body
      assert elem(call, 4) == [async: false]
    end
  end

  defp time do
    {{2016, 1, 21}, {12, 54, 56, {1234, 4}}}
  end
end