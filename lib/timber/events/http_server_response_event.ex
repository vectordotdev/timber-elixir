defmodule Timber.Events.HTTPServerResponseEvent do
  @moduledoc """
  The HTTP response event tracks outgoing HTTP responses.

  Timber can automatically track response events if you
  use a `Plug` based framework through `Timber.Plug`.
  """

  @type t :: %__MODULE__{
    bytes: non_neg_integer,
    headers: headers,
    status: pos_integer,
    time_ms: non_neg_integer
  }

  @type headers :: %{
    cache_control: String.t,
    content_disposition: String.t,
    content_length: non_neg_integer,
    content_type: String.t,
    location: String.t,
    request_id: String.t
  }

  defstruct [:bytes, :headers, :status, :time_ms]

  @recognized_headers ~w(
    cache_control
    content_disposition
    content_length
    content_type
    location
    x-request-id
  )

  @doc """
  Builds a new struct taking care to normalize data into a valid state. This should
  be used, where possible, instead of creating the struct directly.
  """
  def new(opts) do
    struct(__MODULE__, opts)
  end

  @doc """
  Takes a list of two-element tuples representing HTTP response headers and
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

  @spec message(t) :: IO.chardata
  def message(%__MODULE__{status: status, time_ms: time_ms}),
    do: "Sent #{status} in #{time_ms}ms"
end
