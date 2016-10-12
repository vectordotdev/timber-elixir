defmodule Timber.PlugTest do
  use ExUnit.Case, async: false
  use Plug.Test

  require Logger

  describe "Timber.PlugTest.call/2" do
    test "adds an HTTPRequest context to the context stack" do
      conn(:get, "/my_path")
      |> Plug.Conn.fetch_query_params()
      |> Timber.Plug.call([])

      metadata = Logger.metadata()
      timber_context = Keyword.get(metadata, :timber_context, [])

      assert length(timber_context) == 1

      http_request =
        timber_context
        |> List.first()
        |> Map.get(:data)

      assert http_request.host == "www.example.com"
      assert http_request.headers == %{}
      assert http_request.method == :get
      assert http_request.path == "/my_path"
      assert http_request.port == 80
      assert http_request.scheme == :http
      assert http_request.query_params == %{}
    end

    test "adds an HTTPResponse context to the contex stack" do
      conn(:get, "/my_path")
      |> Plug.Conn.fetch_query_params()
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
  end
end
