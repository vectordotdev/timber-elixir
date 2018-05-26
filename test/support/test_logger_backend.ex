defmodule Timber.TestLoggerBackend do
  @moduledoc """
  A module that implements a custom `Logger` backend for use in testing.
  This module can be used to verify events sent with `Logger`.

  Due to the asynchronous nature of `Logger`, a pid can be
  configured, and the backend will send an `:ok` to the configured pid when
  it receives an event.

  `Timber.TestHelpers.add_test_logger_backend/1` is available to handle most
  of the boilerplate set up and teardown.

  Example:
      test "my test" do
        Timber.TestHelpers.add_test_logger_backend(self())

        Logger.error("hello")
        assert_receive :ok
        [{:error, _pid, {Logger, _msg, _ts, metadata}}] = :gen_event.call(Logger, Timber.TestLoggerBackend, :get)

        refute is_nil(Keyword.get(metadata, :pid))
      end
  """
  @behaviour :gen_event

  def init(_) do
    {:ok, %{events: []}}
  end

  def handle_call(:get, %{events: events} = state) do
    {:ok, events, state}
  end

  def handle_call({:configure, opts}, state) do
    callback_pid = Keyword.get(opts, :callback_pid)
    {:ok, :ok, Map.put(state, :callback_pid, callback_pid)}
  end

  def handle_event(
        {_level, _gl, {Logger, _msg, _ts, _md}} = event,
        %{events: events, callback_pid: pid} = state
      ) do
    send_confirmation(pid)
    {:ok, %{state | events: [event | events]}}
  end

  def handle_event(:flush, state) do
    {:ok, state}
  end

  def handle_info(_, state) do
    {:ok, state}
  end

  def code_change(_old, state, _extra) do
    {:ok, state}
  end

  def terminate(_reason, _state) do
    :ok
  end

  defp send_confirmation(nil), do: nil

  defp send_confirmation(pid) do
    send(pid, :ok)
  end
end
