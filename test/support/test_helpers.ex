defmodule Timber.TestHelpers do
  def parse_log_line(line) do
    IO.puts("Splitting #{line}")
    split_string = String.split(line, "@metadata")
    [message, metadata] = split_string
    metadata_map = Poison.decode!(metadata)
    {message, metadata_map}
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
