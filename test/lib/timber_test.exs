defmodule TimberTest do
  use Timber.TestCase

  describe "Timber.start_timer/0" do
    test "starts a timer" do
      timer = Timber.start_timer()
      assert timer
    end
  end

  describe "Timber.duration_ms/1" do
    test "gets the duration" do
      timer = Timber.start_timer()
      :timer.sleep(1)
      duration_ms = Timber.duration_ms(timer)
      assert duration_ms > 1
    end
  end
end