defmodule Timber.Utils.Timestamp do
  @moduledoc false

  alias Timber.LoggerBackend

  @doc """
  Returns the current date and time in UTC including fractional portions of a second
  """
  @spec now() :: LoggerBackend.timestamp
  def now() do
    now = DateTime.utc_now()

    date = {now.year, now.month, now.day}
    time = {now.hour, now.minute, now.second, now.microsecond}
    {date, time}
  end

  @doc """
  Formats a timestamp to the format `YYYY-MM-DDTHH:MM:SS.SSSSSSZ` as chardata

  The precision of the fractional seconds is variable. BEAM only provides
  precision timekeeping to the microsecond, which is equivalent to 1000 nanoseconds.
  However, the Elixir `Logger` library defaults to millisecond precision
  (1000 microseconds or 1,000,000 nanoseconds). When formatting the time
  given by the Elixir `Logger` library, the fractional seconds are represented
  to three decimal places. When formatting the time as microseconds, the
  fractional seconds are represented to six decimal places.

  In some cases, the time keeping library may indicate that the microseconds
  have no precision. In this case, the fractional seconds will be left off
  entirely, resulting in the following format: `YYYY-MM-DDTHH:MM:SSZ`.
  """
  @spec format_timestamp(LoggerBackend.timestamp) :: IO.chardata
  # If the precision for timekeeping of fractional seconds is 0, drop
  # the fractional portion
  def format_timestamp({date, {_, _, _, {_microseconds, 0}} = time}) do
    date = format_date(date)
    time = format_time(time)
    [date | [?T | [time | [?Z]]]]
  end
  # Formatting a timestamp with microseconds
  def format_timestamp({date, {_, _, _, {microseconds, _precision}} = time}) do
    date = format_date(date)
    time = format_time(time)
    partial_seconds = pad6(microseconds)
    [date | [?T | [time | [?. | [partial_seconds | [?Z]]]]]]
  end
  # Formatting a timestamp with milliseconds
  def format_timestamp({date, {_, _, _, milliseconds} = time}) do
    date = format_date(date)
    time = format_time(time)
    milliseconds = pad3(milliseconds)
    [date | [?T | [time | [?. | [milliseconds | [?Z]]]]]]
  end

  # Common functionality for formatting a date as YYYY-MM-DD
  @spec format_date(LoggerBackend.date) :: IO.chardata
  defp format_date({year, month, day}) do
    [Integer.to_string(year), ?-, pad2(month), ?-, pad2(day)]
  end

  # Common functionality for formatting time as HH:MM:SS
  @spec format_time(LoggerBackend.time) :: IO.chardata
  defp format_time({hours, minutes, seconds, _}) do
    [pad2(hours), ?:, pad2(minutes), ?:, pad2(seconds)]
  end

  # These padding functions are based on the original functions in
  # the Elixir `Logger` application. They each return the given
  # integer as chardata padded to a certain number of positions.
  #
  # For example, `pad2(1)` will yield `"01"` (encoded as a binary)
  # and `pad2(12)` will yield `"12"`. Likewise, `pad6(1)` will yield
  # `"000001"`.
  @spec pad2(integer) :: IO.chardata
  defp pad2(int) when int < 10, do: [?0, Integer.to_string(int)]
  defp pad2(int), do: Integer.to_string(int)

  @spec pad3(integer) :: IO.chardata
  defp pad3(int) when int < 10,  do: [?0, ?0, Integer.to_string(int)]
  defp pad3(int) when int < 100, do: [?0, Integer.to_string(int)]
  defp pad3(int), do: Integer.to_string(int)

  @spec pad6(integer) :: IO.chardata
  defp pad6(int) when int < 10,     do: [?0, ?0, ?0, ?0, ?0, Integer.to_string(int)]
  defp pad6(int) when int < 100,    do: [?0, ?0, ?0, ?0, Integer.to_string(int)]
  defp pad6(int) when int < 1000,   do: [?0, ?0, ?0, Integer.to_string(int)]
  defp pad6(int) when int < 10000,  do: [?0, ?0, Integer.to_string(int)]
  defp pad6(int) when int < 100000, do: [?0, Integer.to_string(int)]
  defp pad6(int), do: Integer.to_string(int)
end
