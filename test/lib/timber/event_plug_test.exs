defmodule Timber.Integrations.EventPlugTest do
  #  use Timber.TestCase, async: false
  #  use Plug.Test
  #
  #  import ExUnit.CaptureIO
  #
  #  require Logger
  #
  #  describe "Timber.Integrations.EventPlug.call/2" do
  #    test "logs an incoming HTTP request event" do
  #      conn = generate_conn(:get, [])
  #
  #      log_msg = capture_io(:user, fn ->
  #        Timber.Integrations.EventPlug.call(conn, [])
  #      end)
  #
  #      {_, metadata} = Timber.TestHelpers.parse_log_line(log_msg)
  #
  #      http_request =
  #        Map.get(metadata, "event")
  #        |> Map.get("http_request")
  #
  #      assert http_request["host"] == "www.example.com"
  #      assert http_request["method"] == :get
  #      assert http_request["path"] == "/my_path"
  #      assert http_request["port"] == 80
  #      assert http_request["scheme"] == :http
  #      assert http_request["query_params"] == %{}
  #
  #      refute is_nil(http_request["headers"]["request_id"])
  #    end
  #
  #    test "allows for a custom request ID header name" do
  #      conn = generate_conn(:get, [request_id_header: "req-id"])
  #
  #      log_msg = capture_io(fn ->
  #        Timber.Integrations.EventPlug.call(conn, [request_id_header: "req-id"])
  #      end)
  #
  #      {_, metadata} = Timber.TestHelpers.parse_log_line(log_msg)
  #
  #      http_request =
  #        Map.get(metadata, "event")
  #        |> Map.get("http_request")
  #
  #      refute is_nil(http_request["headers"]["request_id"])
  #    end
  #
  #    test "logs an HTTP response event" do
  #      generate_conn(:get, [])
  #      |> Timber.Integrations.EventPlug.call([])
  #      |> Plug.Conn.send_resp(200, "")
  #
  #      metadata = Logger.metadata()
  #      timber_context = Keyword.get(metadata, :timber_context, [])
  #
  #      assert length(timber_context) == 2
  #
  #      http_response =
  #        timber_context
  #        |> Enum.reverse()
  #        |> List.first()
  #        |> Map.get(:data)
  #
  #      assert http_response.bytes == 0
  #      assert http_response.headers == %{}
  #      assert http_response.status == 200
  #    end
  #
  #    test "correctly calculates HTTP response byte size when using iolist" do
  #      # Weird formatting courtesy of IEx
  #      # The following is iodata that when converted to a binary become:
  #      #
  #      # "{\"errors\":[{\"message\":\"internal server error :*(\",\"key\":\"internal\",\"category\":\"server\"}]}"
  #      #
  #      # which has a byte size of 89 bytes
  #      response_body =
  #        [123,
  #         [[34, ["errors"], 34], 58,
  #          [91,
  #           [[123,
  #             [[34, ["message"], 34], 58, [34, ["internal server error :*("], 34], 44,
  #              [34, ["key"], 34], 58, [34, ["internal"], 34], 44, [34, ["category"], 34],
  #              58, [34, ["server"], 34]], 125]], 93]], 125]
  #
  #      generate_conn(:get, [])
  #      |> Timber.Integrations.EventPlug.call([])
  #      |> Plug.Conn.send_resp(200, response_body)
  #
  #      metadata = Logger.metadata()
  #      timber_context = Keyword.get(metadata, :timber_context, [])
  #
  #      assert length(timber_context) == 2
  #
  #      http_response =
  #        timber_context
  #        |> Enum.reverse()
  #        |> List.first()
  #        |> Map.get(:data)
  #
  #      assert http_response.bytes == 89
  #    end
  #  end
  #
  #  defp generate_conn(:get, opts) do
  #    request_id_header = Keyword.get(opts, :request_id_header, "x-request-id")
  #
  #    conn(:get, "/my_path")
  #    |> Plug.Conn.put_req_header("accept", "application/json")
  #    |> Plug.RequestId.call(request_id_header)
  #    |> Plug.Conn.fetch_query_params()
  #  end
end
