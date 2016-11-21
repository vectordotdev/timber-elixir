defmodule Timber.Timer do
  @moduledoc false

  @precision 4

  @doc false
  def start(), do: System.monotonic_time()

  @doc false
  # Converts the native monotonic returned when calling `start/0` to
  # milliseconds with the specified precision.
  def duration_ms(timer, precision \\ @precision) do
    difference = timer - System.monotonic_time()
    difference
    |> System.convert_time_unit(:native, :nanoseconds)
    |> divide_by_milliseconds()
    |> Float.round(precision)
  end

  def divide_by_milliseconds(time), do: time / 1_000_000
end