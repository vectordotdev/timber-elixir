defmodule Timber.TestGenServer do
  use GenServer

  def start_link(pid) do
    GenServer.start_link(__MODULE__, pid)
  end

  def do_throw(pid) do
    send(pid, :throw)
  end

  def bad_exit(pid) do
    send(pid, :bad_exit)
  end

  def raise(pid) do
    send(pid, :raise)
  end

  def divide(pid, dividend, divisor) do
    send(pid, {:divide, dividend, divisor})
  end

  def divide_call(pid, dividend, divisor) do
    GenServer.call(pid, {:divide, dividend, divisor})
  end

  def init(pid) do
    {:ok, pid}
  end

  def handle_call({:divide, dividend, divisor}, _from, state) do
    {:reply, dividend / divisor, state}
  end

  def handle_info({:divide, dividend, divisor}, state) do
    (dividend / divisor)
    |> Float.to_string()

    {:ok, state}
  end

  def handle_info(:throw, _state) do
    throw("I am throwing")
  end

  def handle_info(:bad_exit, state) do
    {:stop, :bad_exit, state}
  end

  def handle_info(:raise, _state) do
    raise RuntimeError, "raised error"
  end

  def terminate(_, state) do
    send(state, :terminating)
  end
end

defmodule Timber.SimpleTestGenServer do
  use GenServer

  def start_link(pid) do
    GenServer.start_link(__MODULE__, pid)
  end

  def init(pid) do
    {:ok, pid}
  end

  def terminate(_, state) do
    send(state, :terminating)
  end
end
