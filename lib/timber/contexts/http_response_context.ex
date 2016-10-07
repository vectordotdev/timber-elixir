defmodule Timber.Contexts.HTTPResponseContext do
  @moduledoc """
  The HTTP response context tracks outgoing HTTP responses.

  Timber can automatically add responses to the context stack if you
  use a `Plug` based framework through `Timber.Plug`.
  """

  @type t :: %__MODULE__{
    bytes: non_neg_integer,
    headers: headers,
    status: pos_integer
  }

  @type headers :: %{
    cache_control: String.t,
    content_disposition: String.t,
    content_length: non_neg_integer,
    content_type: String.t,
    location: String.t
  }

  defstruct [:bytes, :headers, :status]

  @recognized_headers ~w(
    cache_control
    content_disposition
    content_length
    content_type
    location
  )

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
  defp header_to_keyword({name, value}), do: {String.to_existing_atom(name), value}
end
