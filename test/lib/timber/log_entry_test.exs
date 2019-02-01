defmodule Timber.Events.LogEntryTest do
  use Timber.TestCase

  alias Timber.LogEntry

  describe "Timber.LogEntry.new/4" do
    test "adds an event" do
      entry = LogEntry.new(get_time(), :info, "message", event: %{order_placed: %{total: 100}})
      vm_pid = get_vm_pid()

      assert entry == %Timber.LogEntry{
               context: %{
                 system: %{hostname: get_hostname(), pid: String.to_integer(get_pid())},
                 runtime: %{
                   vm_pid: vm_pid,
                   application: nil,
                   file: nil,
                   function: nil,
                   line: nil,
                   module_name: nil
                 }
               },
               dt: "2016-01-21T12:54:56.001234Z",
               event: %{order_placed: %{total: 100}},
               level: :info,
               message: "message"
             }
    end

    test "adds inline context" do
      entry = LogEntry.new(get_time(), :info, "message", context: %{job: %{id: "abcd"}})
      vm_pid = get_vm_pid()

      assert entry == %Timber.LogEntry{
               dt: "2016-01-21T12:54:56.001234Z",
               event: nil,
               level: :info,
               message: "message",
               context: %{
                 job: %{id: "abcd"},
                 system: %{hostname: get_hostname(), pid: String.to_integer(get_pid())},
                 runtime: %{
                   vm_pid: vm_pid,
                   application: nil,
                   file: nil,
                   function: nil,
                   line: nil,
                   module_name: nil
                 }
               }
             }
    end
  end

  describe "Timber.LogEntry.encode_to_iodata!/3" do
    test "drops blanks" do
      entry = LogEntry.new(get_time(), :info, "message", event: %{type: :type, data: %{}})
      result = LogEntry.encode_to_iodata!(entry, :json)

      result = Jason.decode!(result)

      # The event should be dropped since it's data key is an empty map
      refute Map.has_key?(result, "event")
    end

    test "encodes JSON properly" do
      event_type = :type
      event_data = %{test: "value"}
      message = "message"

      entry =
        LogEntry.new(get_time(), :info, message, event: %{type: event_type, data: event_data})

      result = LogEntry.encode_to_iodata!(entry, :json)

      vm_pid =
        self()
        |> :erlang.pid_to_list()
        |> :erlang.iolist_to_binary()

      # The OS PID is returned as a string from get_pid/0 but represented as an
      # integer in the JSON
      {os_pid, _} =
        get_pid()
        |> Integer.parse()

      hostname = get_hostname()

      result = Jason.decode!(result)

      assert Map.fetch!(result, "message") == "message"
      assert Map.fetch!(result, "level") == "info"
      assert Map.fetch!(result, "dt") == "2016-01-21T12:54:56.001234Z"
      assert Map.fetch!(result, "type") == %{"test" => "value"}

      context = Map.fetch!(result, "context")

      system_context = Map.fetch!(context, "system")
      assert Map.fetch!(system_context, "pid") == os_pid
      assert Map.fetch!(system_context, "hostname") == hostname

      runtime_context = Map.fetch!(context, "runtime")
      assert Map.fetch!(runtime_context, "vm_pid") == vm_pid
    end

    test "encodes logfmt properly" do
      entry = LogEntry.new(get_time(), :info, "message", event: %{order_placed: %{total: 100}})
      hostname = get_hostname()
      system_pid = "#{entry.context.system.pid}"
      vm_pid = entry.context.runtime.vm_pid
      result = LogEntry.encode_to_iodata!(entry, :logfmt)

      assert is_list(result)

      assert to_string(result) ==
               "\n\tContext: system.pid=#{system_pid} system.hostname=#{hostname} runtime.vm_pid=#{
                 vm_pid
               } runtime.module_name= runtime.line= runtime.function= runtime.file= runtime.application="
    end
  end

  defp get_vm_pid do
    self()
    |> :erlang.pid_to_list()
    |> :erlang.iolist_to_binary()
  end

  defp get_hostname do
    case :inet.gethostname() do
      {:ok, hostname} -> to_string(hostname)
      _else -> nil
    end
  end

  defp get_pid do
    System.get_pid()
  end

  defp get_time do
    {{2016, 1, 21}, {12, 54, 56, {1234, 4}}}
  end
end
