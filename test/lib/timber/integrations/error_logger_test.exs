defmodule Timber.Integrations.ErrorLoggerTest do
  use Timber.TestCase
  import Timber.TestHelpers
  alias Timber.FakeHTTPClient
  alias Timber.LoggerBackends.HTTP
  alias Timber.Events.ErrorEvent

  defp add_timber_error_logger() do
    :ok = :error_logger.add_report_handler(Timber.Integrations.ErrorLogger)
    ExUnit.Callbacks.on_exit(fn ->
      :error_logger.delete_report_handler(Timber.Integrations.ErrorLogger)
    end)
  end

  test "logs errors from crashed Task" do
    add_timber_error_logger()
    add_test_logger_backend(self())
    {:ok, pid} = Task.start(fn ->
      Timber.Context.add(%{}, %{a: :b})
      |> Timber.CurrentContext.save()
      raise "Task Error"
    end)

    assert_receive :ok

    [{:error, _pid, {Logger, _msg, _ts, metadata}}] = :gen_event.call(Logger, Timber.TestLoggerBackend, :get)

    assert %ErrorEvent{
      name: "RuntimeError",
      message: "Task Error",
      backtrace: [_line1, _line2, _line3]
    } = Keyword.get(metadata, :event)

    assert Keyword.get(metadata, :pid) == pid
  end

  test "logs errors from GenServer throw" do
    Process.flag(:trap_exit, true)
    add_timber_error_logger()
    add_test_logger_backend(self())

    {:ok, pid} = Timber.TestGenServer.start_link(self())
    Timber.TestGenServer.do_throw(pid)
    assert_receive :ok

    [{:error, _pid, {Logger, _msg, _ts, metadata}}] = :gen_event.call(Logger, Timber.TestLoggerBackend, :get)

    assert %ErrorEvent{
      name: "ErlangError",
      message: "Erlang error: \"I am throwing\"",
    } = Keyword.get(metadata, :event)

    assert Keyword.get(metadata, :pid) == pid
  end

  test "logs errors from GenServer abnormal exit" do
    Process.flag(:trap_exit, true)
    add_timber_error_logger()
    add_test_logger_backend(self())


    {:ok, pid} = Timber.TestGenServer.start_link(self())
    Timber.TestGenServer.bad_exit(pid)
    assert_receive :ok

    [{:error, _pid, {Logger, _msg, _ts, metadata}}] = :gen_event.call(Logger, Timber.TestLoggerBackend, :get)
    assert %ErrorEvent{
      message: "Erlang error: :bad_exit",
      name: "ErlangError",
    } = Keyword.get(metadata, :event)
    assert Keyword.get(metadata, :pid) == pid
  end

  test "logs errors from GenServer handle_call crash" do
    add_timber_error_logger()
    add_test_logger_backend(self())
    Process.flag(:trap_exit, true)

    {:ok, pid} = Timber.TestGenServer.start_link(self())

    assert catch_exit(Timber.TestGenServer.divide_call(pid, 1, 0))
    assert_receive :ok

    [{:error, _pid, {Logger, _msg, _ts, metadata}}] = :gen_event.call(Logger, Timber.TestLoggerBackend, :get)
    assert %ErrorEvent{
      message: "bad argument in arithmetic expression",
      name: "ArithmeticError",
      backtrace: [_, _, _, _]
    } = Keyword.get(metadata, :event)
    assert Keyword.get(metadata, :pid) == pid
  end

  test "logs errors from GenServer handle_info crash" do
    add_timber_error_logger()
    add_test_logger_backend(self())
    Process.flag(:trap_exit, true)

    {:ok, pid} = Timber.TestGenServer.start_link(self())

    Timber.TestGenServer.divide(pid, 1, 0)
    assert_receive :ok

    [{:error, _pid, {Logger, _msg, _ts, metadata}}] = :gen_event.call(Logger, Timber.TestLoggerBackend, :get)
    assert %ErrorEvent{
      message: "bad argument in arithmetic expression",
      name: "ArithmeticError",
      backtrace: [_, _, _, _]
    } = Keyword.get(metadata, :event)
    assert Keyword.get(metadata, :pid) == pid
  end

  test "logs errors from GenServer raise" do
    Process.flag(:trap_exit, true)
    add_timber_error_logger()
    add_test_logger_backend(self())


    {:ok, pid} = Timber.TestGenServer.start_link(self())
    Timber.TestGenServer.raise(pid)
    assert_receive :ok

    [{:error, _pid, {Logger, _msg, _ts, metadata}}] = :gen_event.call(Logger, Timber.TestLoggerBackend, :get)
    assert %ErrorEvent{
      message: "raised error",
      name: "RuntimeError",
      backtrace: [_, _, _, _]
    } = Keyword.get(metadata, :event)
    assert Keyword.get(metadata, :pid) == pid
  end

  test "logs errors from GenServer unexpected message in handle_info/2" do
    add_timber_error_logger()
    add_test_logger_backend(self())

    {:ok, pid} = Timber.SimpleTestGenServer.start_link(self())
    send(pid, :unexpected)
    assert_receive :ok

    [{:error, _pid, {Logger, _msg, _ts, metadata}}] = :gen_event.call(Logger, Timber.TestLoggerBackend, :get)

    assert Keyword.get(metadata, :pid) == pid
  end

  test "logs errors arbitrary errors received by :error_logger" do
    add_timber_error_logger()
    add_test_logger_backend(self())

    :error_logger.error_msg("Failed to start Ranch listener ~p", [self()])

    assert_receive :ok

    [{:error, _pid, {Logger, _msg, _ts, metadata}}] = :gen_event.call(Logger, Timber.TestLoggerBackend, :get)
    assert Keyword.get(metadata, :pid) == self()
  end

  test "logs errors from spawned process crash" do
    add_timber_error_logger()
    add_test_logger_backend(self())

    spawn(fn ->
      raise "Error"
    end)
    assert_receive :ok
    [{:error, _pid, {Logger, _msg, _ts, metadata}}] = :gen_event.call(Logger, Timber.TestLoggerBackend, :get)
    assert %ErrorEvent{
      backtrace: [
        %{
          file: "test/lib/timber/integrations/error_logger_test.exs",
          function: _,
          line: _
        }
      ],
      message: "Error",
      name: "RuntimeError"

    } = Keyword.get(metadata, :event)
  end

  test "Logger events are encodable by the HTTP backend" do
    {:ok, state} = HTTP.init(HTTP, [http_client: FakeHTTPClient])
    add_timber_error_logger()
    add_test_logger_backend(self())

    Task.start(fn ->
      Timber.Context.add(%{}, %{a: :b})
      |> Timber.CurrentContext.save()
      raise "Task Error"
    end)

    assert_receive :ok
    [{:error, pid, {Logger, msg, ts, metadata}}] = :gen_event.call(Logger, Timber.TestLoggerBackend, :get)

    entry = {:error, pid, {Logger, msg, ts, metadata}}

    {:ok, state} = HTTP.handle_event(entry, state)

    HTTP.handle_event(:flush, state)

    calls = FakeHTTPClient.get_async_request_calls()
    assert length(calls) == 1

    call = Enum.at(calls, 0)
    assert elem(call, 0) == :post
    assert elem(call, 1) == "https://logs.timber.io/frames"

    vsn = Application.spec(:timber, :vsn)
    assert elem(call, 2) == %{"Authorization" => "Basic YXBpX2tleQ==", "Content-Type" => "application/msgpack", "User-Agent" => "Timber Elixir/#{vsn} (HTTP)"}

    encoded_body = event_entry_to_msgpack(entry)
    assert elem(call, 3) == encoded_body
  end
end
