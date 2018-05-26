if Code.ensure_loaded?(Plug) do
  defmodule TImber.Integrations.SessionContextPlugTest do
    use Timber.TestCase

    alias Timber.Integrations.SessionContextPlug

    setup do
      conn =
        :get
        |> Plug.Test.conn("/")
        |> Plug.Test.init_test_session(%{})

      {:ok, conn: conn}
    end

    describe "Timber.Integrations.SessionContextPlug.call/2" do
      test "retrieves an existing Timber session ID from the session", %{conn: conn} do
        timber_session_id = "timber"

        conn = Plug.Test.init_test_session(conn, %{:_timber_session_id => timber_session_id})

        conn = SessionContextPlug.call(conn, [])

        conn_session_id = Plug.Conn.get_session(conn, :_timber_session_id)

        context_session_id = get_session_context_id()

        assert conn_session_id == timber_session_id
        assert context_session_id == timber_session_id
      end

      test "sets a new Timber session ID if one does not exist", %{conn: conn} do
        conn = SessionContextPlug.call(conn, [])

        conn_session_id = Plug.Conn.get_session(conn, :_timber_session_id)

        context_session_id = get_session_context_id()

        refute is_nil(conn_session_id)
        refute is_nil(context_session_id)
      end
    end

    def get_session_context_id do
      metadata = Logger.metadata()

      metadata
      |> Keyword.get(:timber_context)
      |> Map.get(:session)
      |> Map.get(:id)
    end
  end
end
