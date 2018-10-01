defmodule Timber.LoggerBackends.InMemory do
  @moduledoc """
  Logger backend for testing only

  This implement a custom `Logger` backend for integration testing when
  implementing code dependent on the Timber library. This module can be used to
  verify events sent with `Logger`.

  To account for the asynchronous nature of `Logger`, a process ID can be
  registered with the backend. When an event is received, the message `:ok` will
  be sent to the corresponding process.
  """

  @behaviour :gen_event

  @doc false
  def init(_) do
    {:ok, %{events: []}}
  end

  @doc false
  def handle_call(:get, %{events: events} = state) do
    {:ok, events, state}
  end

  def handle_call({:configure, opts}, state) do
    callback_pid = Keyword.get(opts, :callback_pid)
    {:ok, :ok, Map.put(state, :callback_pid, callback_pid)}
  end

  @doc false
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

  @doc false
  def handle_info(_, state) do
    {:ok, state}
  end

  @doc false
  def code_change(_old, state, _extra) do
    {:ok, state}
  end

  @doc false
  def terminate(_reason, _state) do
    :ok
  end

  defp send_confirmation(nil), do: nil

  defp send_confirmation(pid) do
    send(pid, :ok)
  end
end
