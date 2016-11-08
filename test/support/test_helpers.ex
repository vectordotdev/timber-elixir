defmodule Timber.TestHelpers do
  def parse_log_line(line) do
    IO.puts("Splitting #{line}")
    split_string = String.split(line, "@timber.io")
    [message, metadata] = split_string
    metadata_map = Poison.decode!(metadata)
    {message, metadata_map}
  end
end
