defmodule Timber.Utils.Plug do
  @moduledoc false

  @doc """
  Fetches the request ID from the connection using the given header name

  The request ID may be added to the connection in a number of ways which
  complicates how we retrieve it. It is usually set by calling the
  Plug.RequestId module on the connection which sets a request ID only
  if one hasn't already been set. If the request ID is set by a service
  prior to Plug, it will be present as a request header. If Plug.RequestId
  generates a request ID, that request ID is only present in the response
  headers. The request headers should always take precedent in
  this function, though.

  This function will return either a single element list containing a two-element
  tuple of the form:

    {"x-request-id", "myrequestid91391"}

  or an empty list. This normalizes the expectation of the header name for
  future processing.

  Note: Plug.RequestId will change an existing request ID if
  it doesn't think the request ID is valid. See
  [request_id.ex](https://github.com/elixir-lang/plug/blob/v1.2.2/lib/plug/request_id.ex#L62).
  """
  @spec get_request_id(Plug.Conn.t, String.t) :: [{String.t, String.t}] | []
  def get_request_id(conn, header_name) do
    case Plug.Conn.get_req_header(conn, header_name) do
      [] -> Plug.Conn.get_resp_header(conn, header_name)
      values -> values
    end
    |> handle_request_id()
  end

  # Helper function to take the result of the header retrieval function
  # and change it to the desired response format for get_request_id/2
  @spec handle_request_id([] | [String.t]) :: [{String.t, String.t}] | []
  defp handle_request_id([]) do
    []
  end

  defp handle_request_id([request_id | _]) do
    [{"x-request-id", request_id}]
  end

  @spec get_client_ip(Plug.Conn.t) :: String.t | nil
  def get_client_ip(%{remote_ip: nil}) do
    nil
  end

  def get_client_ip(%{remote_ip: remote_ip}) do
    remote_ip
    |> :inet.ntoa()
    |> List.to_string()
  end
end
