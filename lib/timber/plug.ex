defmodule Timber.Plug do
  @moduledoc """

  """

  @behaviour Plug

  alias Timber.Contexts.{HTTPRequestContext, HTTPResponseContext}

  @spec init(Plug.opts) :: Plug.opts
  def init(opts) do
    opts
  end

  @spec call(Plug.Conn.t, Plug.opts) :: Plug.Conn.t
  def call(conn, _opts) do
    host = conn.host
    port = conn.port
    scheme = conn.scheme
    method = conn.method
    path = conn.request_path
    headers = HTTPRequestContext.headers_from_list(conn.req_headers)
    query_params = conn.query_params

    context = %HTTPRequestContext{
      host: host,
      port: port,
      scheme: scheme,
      method: method,
      path: path,
      headers: headers,
      query_params: query_params
    }

    Timber.add_context(context)

    Plug.Conn.register_before_send(conn, &add_response_context/1)
  end

  @spec add_response_context(Plug.Conn.t) :: Plug.Conn.t
  defp add_response_context(conn) do
    bytes = :erlang.byte_size(conn.resp_body)
    status = Plug.Conn.Status.code(conn.status)
    headers = HTTPResponseContext.headers_from_list(conn.resp_headers)

    context = %HTTPResponseContext{
      bytes: bytes,
      headers: headers,
      status: status
    }

    Timber.add_context(context)

    conn
  end
end
