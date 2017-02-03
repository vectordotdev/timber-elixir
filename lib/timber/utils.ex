defmodule Timber.Utils do
  @moduledoc """
  Utility functions for Timber
  """

  alias Timber.LoggerBackend

  @doc """
  Drops any `nil` values from the given map

  Only applies to the root level of the map
  """
  @spec drop_nil_values(map) :: map
  def drop_nil_values(map) do
    Enum.reject(map, fn
      {_k, nil} -> true
      {_k, []} -> true
      {_k, m} when is_map(m) and map_size(m) == 0 -> true
      _ -> false
    end)
    |> Enum.into(%{})
  end

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

  @doc """
  Returns a string representation of the module name with the `Elixir.` prefix stripped.
  """
  def module_name(module) do
    module
    |> List.wrap()
    |> Module.concat()
    |> Atom.to_string()
    |> String.replace_prefix("Elixir.", "")
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

  @doc false
  # Constructs a full path from the given parts
  def full_path(path, query_string) do
    %URI{path: path, query: query_string}
    |> URI.to_string()
  end

  @doc false
  # Constructs a full path from the given parts
  def full_url(scheme, host, path, port, query_string) do
    %URI{scheme: scheme, host: host, path: path, port: port, query: query_string}
    |> URI.to_string()
  end

  @doc false
  # Normalizes a URL into a Keyword.t that maps to our HTTP event fields.
  def normalize_url(url) when is_binary(url) do
    uri = URI.parse(url)
    [
      host: uri.authority,
      path: uri.path,
      port: uri.port,
      query_string: uri.query,
      scheme: uri.scheme
    ]
  end
  def normalize_url(_url), do: []

  @doc false
  # Normalizes HTTP methods into a value expected by the Timber API.
  def normalize_method(method) when is_atom(method) do
    method
    |> Atom.to_string()
    |> normalize_method()
  end
  def normalize_method(method) when is_binary(method), do: String.upcase(method)
  def normalize_method(method), do: method

  @doc false
  # Normalizes HTTP headers into a structure expected by the Timber API.
  def normalize_headers(headers, allowed_keys) when is_list(headers) do
    headers
    |> List.flatten()
    |> Enum.into(%{})
    |> normalize_headers(allowed_keys)
  end
  def normalize_headers(headers, allowed_keys) when is_map(headers) do
    headers
    |> Enum.filter_map(fn {k,_v} -> k in allowed_keys end, &header_to_keyword/1)
    |> Enum.into(%{})
  end
  def normalize_headers(headers), do: headers

  @doc false
  # Convenience method that checks if the value is an atom and also converts it to a string.
  def try_atom_to_string(val) when is_atom(method), do: Atom.to_string(method)
  def try_atom_to_string(val), do: val


  @doc false
  # Converts header key value pairs into a structure expected by the Timber API.
  @spec header_to_keyword({String.t, String.t}) :: {atom, String.t}
  defp header_to_keyword({"x-request-id", id}), do: {:request_id, id}
  defp header_to_keyword({name, value}) do
    atom_name =
      name
      |> String.replace("-", "_")
      |> String.to_existing_atom()
    {atom_name, value}
  end
end
