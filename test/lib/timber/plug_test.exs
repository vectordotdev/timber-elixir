defmodule Timber.PlugTest do
  use ExUnit.Case, async: false
  use Plug.Test

  require Logger

  describe "Timber.PlugTest.call/2" do
    test "adds an HTTPRequest context to the context stack" do
      generate_conn(:get, [])
      |> Timber.Plug.call([])

      metadata = Logger.metadata()
      timber_context = Keyword.get(metadata, :timber_context, [])

      assert length(timber_context) == 1

      http_request =
        timber_context
        |> List.first()
        |> Map.get(:data)

      assert http_request.host == "www.example.com"
      assert http_request.method == :get
      assert http_request.path == "/my_path"
      assert http_request.port == 80
      assert http_request.scheme == :http
      assert http_request.query_params == %{}

      refute is_nil(http_request.headers.request_id)
    end

    test "allows for a custom request ID header name" do
      generate_conn(:get, [request_id_header: "req-id"])
      |> Timber.Plug.call([request_id_header: "req-id"])

      metadata = Logger.metadata()
      timber_context = Keyword.get(metadata, :timber_context, [])

      assert length(timber_context) == 1

      http_request =
        timber_context
        |> List.first()
        |> Map.get(:data)

      refute is_nil(http_request.headers.request_id)
    end

    test "adds an HTTPResponse context to the context stack" do
      generate_conn(:get, [])
      |> Timber.Plug.call([])
      |> Plug.Conn.send_resp(200, "")

      metadata = Logger.metadata()
      timber_context = Keyword.get(metadata, :timber_context, [])

      assert length(timber_context) == 2

      http_response =
        timber_context
        |> Enum.reverse()
        |> List.first()
        |> Map.get(:data)

      assert http_response.bytes == 0
      assert http_response.headers == %{}
      assert http_response.status == 200
    end

    test "correctly calculates HTTPResponse byte size when using iolist" do
      # Weird formatting courtesy of IEx
      # The following is iodata that when converted to a binary become:
      #
      # "{\"errors\":[{\"message\":\"internal server error :*(\",\"key\":\"internal\",\"category\":\"server\"}]}"
      #
      # which has a byte size of 89 bytes
      response_body =
        [123,
         [[34, ["errors"], 34], 58,
          [91,
           [[123,
             [[34, ["message"], 34], 58, [34, ["internal server error :*("], 34], 44,
              [34, ["key"], 34], 58, [34, ["internal"], 34], 44, [34, ["category"], 34],
              58, [34, ["server"], 34]], 125]], 93]], 125]

      generate_conn(:get, [])
      |> Timber.Plug.call([])
      |> Plug.Conn.send_resp(200, response_body)

      metadata = Logger.metadata()
      timber_context = Keyword.get(metadata, :timber_context, [])

      assert length(timber_context) == 2

      http_response =
        timber_context
        |> Enum.reverse()
        |> List.first()
        |> Map.get(:data)

      assert http_response.bytes == 89
    end
  end

  defp generate_conn(:get, opts) do
    request_id_header = Keyword.get(opts, :request_id_header, "x-request-id")

    conn(:get, "/my_path")
    |> Plug.Conn.put_req_header("accept", "application/json")
    |> Plug.RequestId.call(request_id_header)
    |> Plug.Conn.fetch_query_params()
  end
end
