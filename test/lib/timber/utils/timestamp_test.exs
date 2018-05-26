defmodule Timber.Utils.TimestampTest do
  use Timber.TestCase

  alias Timber.Utils.Timestamp

  describe "Timber.Utils.Timestamp.format_timestamp/1" do
    test "formats timestamp with milliseconds correctly" do
      # 2005-05-07 00h 15m 35s 928 ms
      expected_format = "2005-05-07T00:15:35.928Z"

      timestamp = {{2005, 05, 07}, {00, 15, 35, 928}}

      formatted_timestamp =
        Timestamp.format_timestamp(timestamp)
        |> IO.chardata_to_string()

      assert formatted_timestamp == expected_format
    end

    test "formats timestamp with milliseconds with no precision correctly" do
      # 2016-12-23 09h 06m 11m 102919 µ-seconds at 0 precision
      expected_format = "2016-12-23T09:06:11Z"

      timestamp = {{2016, 12, 23}, {09, 06, 11, {102_919, 0}}}

      formatted_timestamp =
        Timestamp.format_timestamp(timestamp)
        |> IO.chardata_to_string()

      assert formatted_timestamp == expected_format
    end

    test "formats timestamp with milliseconds with any precision to six digits" do
      # 2016-12-23 09h 06m 11m 102919 µ-seconds at 2 precision
      expected_format = "2016-12-23T09:06:11.102919Z"

      timestamp = {{2016, 12, 23}, {09, 06, 11, {102_919, 2}}}

      formatted_timestamp =
        Timestamp.format_timestamp(timestamp)
        |> IO.chardata_to_string()

      assert formatted_timestamp == expected_format
    end
  end
end
