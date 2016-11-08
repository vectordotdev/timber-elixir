defmodule Timber.Events.HTTPRequestEvent do
  @moduledoc """
  The HTTP request event tracks incoming HTTP requests

  Timber can automatically track incoming HTTP requests if
  you use a `Plug` based framework through the `Timber.Plug`.
  """

  @type t :: %__MODULE__{
    host: String.t | nil,
    description: String.t | nil,
    headers: headers | nil,
    method: method | nil,
    path: String.t | nil,
    port: pos_integer | nil,
    scheme: scheme | nil,
    query_params: %{String.t => String.t} | nil,
  }

  @type method :: :connect | :delete | :get | :head | :options | :post | :put | :trace

  @type scheme :: :https | :http

  @type headers :: %{
    content_type: String.t | nil,
    remote_addr: String.t | nil,
    referrer: String.t | nil,
    request_id: String.t | nil,
    user_agent: String.t | nil
  }

  defstruct [:host, :headers, :method, :path, :port, :scheme, :query_params, :description]

  @recognized_headers ~w(
    content-type
    referrer
    user-agent
    x-forwarded-for
    x-request-id
  )

  def new(opts) do
    event = struct(__MODULE__, opts)
    description = "Received request for #{event.path}"

    %__MODULE__{event | description: description}
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
  defp header_to_keyword({"content-type", content_type}), do: {:content_type, content_type}
  defp header_to_keyword({"referrer", referrer}), do: {:referrer, referrer}
  defp header_to_keyword({"user-agent", user_agent}), do: {:user_agent, user_agent}
  defp header_to_keyword({"x-forwarded-for", ip}), do: {:remote_addr, ip}
  defp header_to_keyword({"x-request-id", id}), do: {:request_id, id}

  @spec method_from_string(String.t) :: method
  def method_from_string(method) do
    String.downcase(method)
    |> String.to_existing_atom()
  end
end
