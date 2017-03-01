defmodule Timber.Transports.HTTPTest do
  use Timber.TestCase

  alias Timber.FakeHTTPClient
  alias Timber.LogEntry
  alias Timber.Transports.HTTP

  describe "Timber.Transports.HTTP.init/0" do
    test "configures properly" do
      {:ok, state} = HTTP.init()
      assert state.api_key == "api_key"
    end

    test "starts the flusher" do
      HTTP.init()
      assert_receive(:outlet, 1100)
    end
  end

  describe "Timber.Transports.HTTP.configure/2" do
    test "requires an API key" do
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
    test "issues a request" do
      entry = LogEntry.new(time(), :info, "message", [event: %{type: :type, data: %{}}])
      {:ok, state} = HTTP.init()
      {:ok, state} = HTTP.write(entry, state)
      HTTP.flush(state)
      calls = FakeHTTPClient.get_request_calls()
      assert length(calls) == 1
      call = Enum.at(calls, 0)
      assert elem(call, 0) == :post
      assert elem(call, 1) == "https://logs.timber.io/frames"
      vsn = Application.spec(:timber, :vsn)
      assert elem(call, 2) == %{"Authorization" => "Basic YXBpX2tleQ==", "Content-Type" => "application/msgpack", "User-Agent" => "Timber Elixir/#{vsn} (HTTP)"}
      {:ok, encoded_body} = Msgpax.pack([LogEntry.to_map!(entry)])
      assert elem(call, 3) == encoded_body
    end

    test "issues a request with chardata" do
      entry = LogEntry.new(time(), :info, ["this", "is", "a", "message"], [event: %{type: :type, data: %{}}])
      {:ok, state} = HTTP.init()
      {:ok, state} = HTTP.write(entry, state)
      HTTP.flush(state)
      calls = FakeHTTPClient.get_request_calls()
      assert length(calls) == 1
      call = Enum.at(calls, 0)
      log_entry_map =
        entry
        |> LogEntry.to_map!()
        |> Map.put(:message, IO.chardata_to_string(entry.message))
      {:ok, encoded_body} = Msgpax.pack([log_entry_map])
      assert elem(call, 3) == encoded_body
    end
  end

  describe "Timber.Transports.HTTP.handle_info/2" do
    test "handles the outlet properly" do
      entry = LogEntry.new(time(), :info, "message", [event: %{type: :type, data: %{}}])
      {:ok, state} = HTTP.init()
      {:ok, state} = HTTP.write(entry, state)
      {:ok, new_state} = HTTP.handle_info(:outlet, state)
      calls = FakeHTTPClient.get_request_calls()
      assert length(calls) == 1
      assert length(new_state.buffer) == 0
      assert_receive(:outlet, 1100)
    end

    test "ignores everything else" do
      {:ok, state} = HTTP.init()
      {:ok, new_state} = HTTP.handle_info(:unknown, state)
      assert state == new_state
    end
  end

  describe "Timber.Transports.HTTP.wait_on_request/1" do

  end

  describe "Timber.Transports.HTTP.write/0" do
    test "buffers the message if the buffer is not full" do
      entry = LogEntry.new(time(), :info, "message", [event: %{type: :type, data: %{}}])
      {:ok, state} = HTTP.init()
      {:ok, new_state} = HTTP.write(entry, state)
      assert new_state.buffer == [entry]
      calls = FakeHTTPClient.get_request_calls()
      assert length(calls) == 0
    end

    test "flushes if the buffer is full" do
      entry = LogEntry.new(time(), :info, "message", [event: %{type: :type, data: %{}}])
      {:ok, state} = HTTP.init()
      state = %{state | max_buffer_size: 1}
      HTTP.write(entry, state)
      calls = FakeHTTPClient.get_request_calls()
      assert length(calls) == 1
    end
  end

  defp time do
    {{2016, 1, 21}, {12, 54, 56, {1234, 4}}}
  end
end