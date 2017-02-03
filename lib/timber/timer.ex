defmodule Timber.Timer do
  @moduledoc false

  @precision 6

  @doc """
  Starts a timer for timing code execution. This timer can then be passed
  to `Timber.Timer.duration_ms/1`.

  ## Example

    iex> timer = Timber.Timer.start_timer()
    iex> # ... code to time ...
    iex> ms = Timber.Timer.duration_ms(timer)

  """
  def start(), do: System.monotonic_time()

  @doc """
  Calculates the duration of timer in milliseconds. The millisecond
  returned is a Float with a default precision of 4. You can modify
  this by passing a new precision as the second argument.
  """
  def duration_ms(timer, precision \\ @precision) do
    (System.monotonic_time() - timer)
    |> System.convert_time_unit(:native, :nanoseconds)
    |> divide_by_milliseconds()
    |> Float.round(precision)
  end

  defp divide_by_milliseconds(time) do
    time / 1_000_000
  end
end