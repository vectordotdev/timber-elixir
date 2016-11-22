defmodule Timber.Timer do
  @moduledoc false

  @precision 4

  @doc false
  def start(), do: System.monotonic_time()

  @doc false
  # Determines the duration passed since the timer passed. `timer` should
  # be the value returned when calling `start/0`.
  def duration_ms(timer, precision \\ @precision) do
    difference = System.monotonic_time() - timer
    difference
    |> System.convert_time_unit(:native, :nanoseconds)
    |> divide_by_milliseconds()
    |> Float.round(precision)
  end

  defp divide_by_milliseconds(time), do: time / 1_000_000

  def convert_to_time_ms(opts, timer_key, time_ms_key) do
    timer = Keyword.get(opts, timer_key)
    if timer do
      time_ms = Timer.duration_ms(timer)
      opts
      |> Keyword.delete(timer_key)
      |> Keyword.put(time_ms_key, time_ms)
    else
      opts
    end
  end
end