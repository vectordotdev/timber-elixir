defmodule Timber.LoggerBackends.HTTPTest do
  use Timber.TestCase
  import Timber.TestHelpers, only: [event_entry_to_log_entry: 1, event_entry_to_msgpack: 1]
  import ExUnit.CaptureIO

  alias Timber.HTTPClients.Fake, as: FakeHTTPClient
  alias Timber.LoggerBackends.HTTP

  setup do
    {:ok, state} = HTTP.init(HTTP, http_client: FakeHTTPClient, flush_interval: 0)

    {:ok, state: state}
  end

  describe "Timber.LoggerBackends.HTTP.init/1" do
    test "configures properly" do
      {:ok, state} = HTTP.init(HTTP)
      assert state.api_key == "api_key"
    end

    test "starts the flusher" do
      FakeHTTPClient.stub(:request, fn :get,
                                       "https://api.timber.io/installer/application",
                                       %{"Authorization" => "Basic YXBpX2tleQ=="},
                                       _ ->
        {:ok, 204, %{}, ""}
      end)

      HTTP.init(HTTP)
      assert_receive(:outlet)
    end
  end

  describe "Timber.LoggerBackends.HTTP.handle_call/2" do
    test "{:configure, options} allows the API key to be nil", %{state: state} do
      {:ok, :ok, new_state} = HTTP.handle_call({:configure, [api_key: nil]}, state)

      assert is_nil(new_state.api_key)
    end

    test "{:configure, options} message updates the api key", %{state: state} do
      {:ok, :ok, new_state} = HTTP.handle_call({:configure, [api_key: "new_api_key"]}, state)
      assert new_state.api_key == "new_api_key"
    end

    test "{:configure, options} message updates the max_buffer_size", %{state: state} do
      {:ok, :ok, new_state} = HTTP.handle_call({:configure, [max_buffer_size: 100]}, state)
      assert new_state.max_buffer_size == 100
    end
  end

  describe "Timber.LoggerBackends.HTTP.handle_event/2" do
    test ":flush message fails silently without an API key", %{state: state} do
      entry = {:info, self(), {Logger, "message", time(), [event: %{type: :type, data: %{}}]}}

      {:ok, :ok, state} = HTTP.handle_call({:configure, [api_key: nil]}, state)
      {:ok, state} = HTTP.handle_event(entry, state)

      {:ok, _state} = HTTP.handle_event(:flush, state)
    end

    test ":flush message issues a request", %{state: state} do
      entry = {:info, self(), {Logger, "message", time(), [event: %{type: :type, data: %{}}]}}

      {:ok, state} = HTTP.handle_event(entry, state)
      HTTP.handle_event(:flush, state)

      calls = FakeHTTPClient.get_async_request_calls()
      assert length(calls) == 1

      call = Enum.at(calls, 0)
      assert elem(call, 0) == :post
      assert elem(call, 1) == "https://logs.timber.io/frames"

      vsn = Application.spec(:timber, :vsn)

      assert elem(call, 2) == %{
               "Authorization" => "Basic YXBpX2tleQ==",
               "Content-Type" => "application/msgpack",
               "User-Agent" => "timber-elixir/#{vsn}"
             }

      encoded_body = event_entry_to_msgpack(entry)
      assert elem(call, 3) == encoded_body
    end

    test ":flush message issues a request with chardata", %{state: state} do
      entry = {:info, self(), {Logger, "message", time(), [event: %{type: :type, data: %{}}]}}

      {:ok, state} = HTTP.handle_event(entry, state)
      HTTP.handle_event(:flush, state)

      calls = FakeHTTPClient.get_async_request_calls()
      assert length(calls) == 1

      call = Enum.at(calls, 0)
      encoded_body = event_entry_to_msgpack(entry)
      assert elem(call, 3) == encoded_body
    end

    test "failure of the http client will not cause the :flush message to raise", %{state: state} do
      entry = {:info, self(), {Logger, "message", time(), [event: %{type: :type, data: %{}}]}}

      expected_method = :post
      expected_url = "https://logs.timber.io/frames"
      vsn = Application.spec(:timber, :vsn)

      expected_headers = %{
        "Authorization" => "Basic YXBpX2tleQ==",
        "Content-Type" => "application/msgpack",
        "User-Agent" => "timber-elixir/#{vsn}"
      }

      expected_body = event_entry_to_msgpack(entry)

      FakeHTTPClient.stub(:async_request, fn ^expected_method,
                                             ^expected_url,
                                             ^expected_headers,
                                             ^expected_body ->
        {:error, :connect_timeout}
      end)

      {:ok, state} = HTTP.handle_event(entry, state)
      {:ok, _} = HTTP.handle_event(:flush, state)
    end

    test "message event buffers the message if the buffer is not full", %{state: state} do
      entry = {:info, self(), {Logger, "message", time(), [event: %{type: :type, data: %{}}]}}

      {:ok, new_state} = HTTP.handle_event(entry, state)
      assert new_state.buffer == [event_entry_to_log_entry(entry)]
      calls = FakeHTTPClient.get_async_request_calls()
      assert calls == []
    end

    test "flushes if the buffer is full", %{state: state} do
      entry = {:info, self(), {Logger, "message", time(), [event: %{type: :type, data: %{}}]}}
      state = %{state | max_buffer_size: 1}
      HTTP.handle_event(entry, state)
      calls = FakeHTTPClient.get_async_request_calls()
      assert length(calls) == 1
    end
  end

  describe "Timber.LoggerBackends.HTTP.handle_info/2" do
    test "handles the outlet properly", %{state: state} do
      entry = {:info, self(), {Logger, "message", time(), [event: %{type: :type, data: %{}}]}}
      {:ok, state} = HTTP.handle_event(entry, state)
      {:ok, new_state} = HTTP.handle_info(:outlet, state)
      calls = FakeHTTPClient.get_async_request_calls()
      assert length(calls) == 1
      assert new_state.buffer == []
      assert_receive(:outlet)
    end

    test "emits debug log when encoding fails", %{state: state} do
      Application.put_env(:timber, :debug_io_device, :stdio)
      bad_tuple = {:bad, :tuple}

      entry =
        {:info, self(),
         {Logger, "message", time(), [event: %{type: :type, data: %{tuple: bad_tuple}}]}}

      log_output =
        capture_io(fn ->
          {:ok, state} = HTTP.handle_event(entry, state)
          {:ok, new_state} = HTTP.handle_info(:outlet, state)
          assert new_state.buffer == []
        end)

      Application.delete_env(:timber, :debug_io_device)
      assert log_output =~ "Log transmission failed. Msgpax.Packer Protocol not implemented"
      assert log_output =~ "#{inspect(bad_tuple)}"
    end

    test "ignores everything else", %{state: state} do
      {:ok, new_state} = HTTP.handle_info(:unknown, state)
      assert state == new_state
    end
  end

  defp time do
    {{2016, 1, 21}, {12, 54, 56, {1234, 4}}}
  end
end
