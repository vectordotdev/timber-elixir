defmodule Timber.Integrations.HTTPContextPlugTest do
  use Timber.TestCase

  alias Timber.Integrations.HTTPContextPlug

  setup do
    conn = Plug.Test.conn(:get, "/")

    {:ok, conn: conn}
  end

  describe "Timber.Integrations.HTTPContextPlug.call/2" do
    test "captures HTTP method" do
      conn = Plug.Test.conn(:delete, "/")

      HTTPContextPlug.call(conn, [])

      context = get_request_context()

      assert context.method == "DELETE"
    end

    test "captures HTTP path" do
      conn = Plug.Test.conn(:get, "/articles/1234")

      HTTPContextPlug.call(conn, [])

      context = get_request_context()

      assert context.path == "/articles/1234"
    end

    test "captures remote address", %{conn: conn} do
      conn = %Plug.Conn{ conn | remote_ip: {127, 0, 0, 1} }

      HTTPContextPlug.call(conn, [])

      context = get_request_context()

      assert context.remote_addr == "127.0.0.1"
    end

    test "captures X-Request-ID header", %{conn: conn} do
      request_id = "abcdefg"

      new_conn = Plug.Conn.put_req_header(conn, "x-request-id", request_id)

      HTTPContextPlug.call(new_conn, [])

      context = get_request_context()

      context_request_id = context.request_id

      assert context_request_id == request_id
    end

    test "captures request ID from custom header", %{conn: conn} do
      request_id_header = "x-timbertrace-id"
      request_id = "abcdefg"

      new_conn = Plug.Conn.put_req_header(conn, request_id_header, request_id)

      HTTPContextPlug.call(new_conn, [request_id_header: request_id_header])

      context = get_request_context()

      context_request_id = context.request_id

      assert context_request_id == request_id
    end
  end

  def get_request_context() do
    metadata = Logger.metadata()

    metadata
    |> Keyword.get(:timber_context)
    |> Map.get(:http)
  end
end
