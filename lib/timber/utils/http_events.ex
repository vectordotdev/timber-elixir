defmodule Timber.Utils.HTTPEvents do
  @moduledoc false

  alias Timber.Config

  def format_time_ms(time_ms) when is_integer(time_ms),
    do: [Integer.to_string(time_ms), "ms"]

  def format_time_ms(time_ms) when is_float(time_ms) and time_ms >= 1,
    do: [:erlang.float_to_binary(time_ms, decimals: 2), "ms"]

  def format_time_ms(time_ms) when is_float(time_ms) and time_ms < 1,
    do: [:erlang.float_to_binary(time_ms * 1000, decimals: 0), "µs"]

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
  # Attemps to grab the request ID from the headers
  def get_request_id_from_headers(%{"x-request-id" => request_id}), do: request_id

  def get_request_id_from_headers(%{"request-id" => request_id}), do: request_id

  def get_request_id_from_headers(_headers), do: nil

  @doc false
  # Normalizes the body into a truncated string
  def normalize_body(nil = body), do: body

  def normalize_body("" = body), do: body

  def normalize_body(body) when is_map(body) do
    case Config.json_encoder().(body) do
      {:ok, json} -> normalize_body(to_string(json))
      _ -> nil
    end
  end

  def normalize_body(body) when is_binary(body) do
    limit = Config.http_body_size_limit()
    String.slice(body, 0..limit)
  end

  @doc false
  # Normalizes HTTP headers into a structure expected by the Timber API.
  def normalize_headers(headers) when is_list(headers) do
    headers
    |> List.flatten()
    |> Enum.into(%{})
    |> normalize_headers()
  end

  def normalize_headers(headers) when is_map(headers) do
    headers
    |> Enum.map(&normalize_header/1)
    |> Enum.into(%{})
  end

  def normalize_headers(headers), do: headers

  @doc false
  # Normalizes an individual header
  @spec normalize_header({String.t, String.t}) :: {String.t, String.t}
  defp normalize_header({name, value}) do
    {String.downcase(name), String.slice(value, 0..255)}
  end

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
  # Convenience method that checks if the value is an atom and also converts it to a string.
  def try_atom_to_string(val) when is_atom(val), do: Atom.to_string(val)

  def try_atom_to_string(val), do: val
end
