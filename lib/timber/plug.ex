defmodule Timber.Plug do
  @moduledoc """

  """

  @behaviour Plug

  @spec init(Plug.opts) :: Plug.opts
  def init(opts) do
    opts
  end

  @spec call(Plug.Conn.t, Plug.opts) :: Plug.Conn.t
  def call(conn, _opts) do
    host = conn.host
    port = conn.port
    scheme = Atom.to_string(conn.scheme)
    method = conn.method
    path = conn.request_path
    headers = conn.req_headers
    query_params = conn.query_params

    Timber.add_http_request_context(host, port, scheme, method, path, headers, query_params)

    Plug.Conn.register_before_send(conn, &add_response_context/1)
  end

  @spec add_response_context(Plug.Conn.t) :: Plug.Conn.t
  defp add_response_context(conn) do
    bytes = :erlang.byte_size(conn.resp_body)
    headers = conn.resp_headers
    status = Plug.Conn.Status.code(conn.status)

    Timber.add_http_response_context(bytes, headers, status)

    conn
  end
end
