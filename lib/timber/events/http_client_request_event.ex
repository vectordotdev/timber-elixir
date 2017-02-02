defmodule Timber.Events.HTTPClientRequestEvent do
  @moduledoc """
  The HTTP client request event tracks *outgoing* HTTP requests from your application.
  This event is HTTP client agnostic, use it with your HTTP client of choice.

  ## Hackney Example

    iex> method = :get
    iex> url = "https://some.api.com/path?query=1"
    iex> headers_list = [{"Accept", "application/json"}]
    iex> Timber.Events.HTTPClientRequestEvent.new(
      method: method,
      url: url,
      headers_list: headers_list
    )

  """

  alias Timber.Events.HTTP

  @type headers :: %{
    accept: String.t | nil,
    content_type: String.t | nil,
    request_id: String.t | nil,
    user_agent: String.t | nil
  }
  @type host :: String.t
  @type method :: String.t
  @type path :: String.t
  @type http_port :: pos_integer
  @type query_string :: String.t | nil
  @type scheme :: :http | :https
  @type service_name :: String.t

  @type t :: %__MODULE__{
    headers: headers | nil,
    host: host,
    method: method,
    path: path,
    port: http_port,
    query_string: query_string,
    scheme: scheme,
    service_name: service_name | nil
  }

  @recognized_headers ~w(
    accept
    content-type
    user-agent
    x-request-id
  )

  @enforce_keys [:host, :method, :path, :port, :scheme, :service_name]
  defstruct [:headers, :host, :method, :path, :port, :scheme, :service_name, :query_string]

  # Constructs a full path from the given parts
  defp full_path(%__MODULE__{path: path, query_string: query_string}) do
    %URI{path: path, query: query_string}
    |> URI.to_string()
  end

  @doc """
  Builds a new struct taking care to normalize data into a valid state. This should
  be used, where possible, instead of creating the struct directly.
  """
  def new(opts) do
    url = Keyword.get(opts, :url)
    opts = if url do
      uri = URI.parse(url)
      opts
      |> Keyword.merge([
        host: uri.host,
        path: uri.path,
        query_string: uri.query,
        scheme: uri.schema
      ])
      |> Keyword.delete(:url)
    else
      opts
    end

    method = Keyword.get(opts, :method)
    opts = if method do
      normalized_method =
        method
        |> Atom.to_string()
        |> String.upcase()
        |> String.to_existing_atom()
      Keyword.put(opts, :method, HTTP.normalize_method(method))
    else
      opts
    end
    struct(__MODULE__, opts)
  end

  @doc """
  Takes a list of two-element tuples representing HTTP request headers and
  returns a map of the recognized headers Timber handles
  """
  @spec headers_from_list([{String.t, String.t}]) :: headers
  def headers_from_list(headers) do
    Enum.filter_map(headers, &header_filter/1, &header_to_keyword/1)
    |> Enum.into(%{})
  end

  @spec headers_from_list({String.t, String.t}) :: boolean
  defp header_filter({name, _}) when name in @recognized_headers, do: true
  defp header_filter(_), do: false

  @spec header_to_keyword({String.t, String.t}) :: {atom, String.t}
  defp header_to_keyword({"x-request-id", id}), do: {:request_id, id}
  defp header_to_keyword({name, value}) do
    atom_name =
      name
      |> String.replace("-", "_")
      |> String.to_existing_atom()
    {atom_name, value}
  end

  @doc """
  Default message used when logging this event.
  """
  @spec message(t) :: IO.chardata
  def message(%__MODULE__{method: method, service_name: service_name} = event),
    do: ["Outgoing HTTP request to ", service_name, " [", method, "] ", full_path(event)]

  @spec method_from_string(String.t) :: method
  def method_from_string(method) do
    String.downcase(method)
    |> String.to_existing_atom()
  end
end
