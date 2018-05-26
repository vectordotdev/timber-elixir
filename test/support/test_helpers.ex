defmodule Timber.TestHelpers do
  def parse_log_line(line) do
    IO.puts("Splitting #{line}")
    split_string = String.split(line, "@metadata")
    [message, metadata] = split_string
    metadata_map = Poison.decode!(metadata)
    {message, metadata_map}
  end

  def add_test_logger_backend(pid) when is_pid(pid) do
    {:ok, _pid} = Logger.add_backend(Timber.TestLoggerBackend)
    Logger.configure_backend(Timber.TestLoggerBackend, callback_pid: pid)
    :ok = Logger.remove_backend(:console)

    ExUnit.Callbacks.on_exit(fn ->
      :ok = Logger.remove_backend(Timber.TestLoggerBackend)
      {:ok, _pid} = Logger.add_backend(:console)
    end)
  end

  def event_entry_to_log_entry({level, _, {Logger, message, ts, metadata}}) do
    Timber.LogEntry.new(ts, level, message, metadata)
  end

  def event_entry_to_msgpack(entry) do
    log_entry = event_entry_to_log_entry(entry)

    map =
      log_entry
      |> Timber.LogEntry.to_map!()
      |> Map.put(:message, IO.chardata_to_string(log_entry.message))

    Msgpax.pack!([map])
  end

  defmacro skip_min_elixir_version(version) do
    quote do
      unless(Version.match?(System.version(), "~> #{unquote(version)}")) do
        @tag :skip
      end
    end
  end
end
