defmodule Timber.Timer do
  @moduledoc false

  @precision 4

  @doc false
  def start(), do: System.monotonic_time()

  @doc false
  # Converts the native monotonic returned when calling `start/0` to
  # milliseconds with the specified precision.
  def duration_ms(timer, precision \\ @precision) do
    start_nanoseconds = System.convert_time_unit(timer, :native, :nanoseconds)
    end_nanoseconds = System.convert_time_unit(System.monotonic_time(), :native, :nanoseconds)

    # Convert to milliseconds with a precision
    time_ms = (start_nanoseconds - end_nanoseconds) / 1_000_000 # convert to milliseconds
    time_ms = Float.round(time_ms, precision)
  end
end