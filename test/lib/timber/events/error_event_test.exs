defmodule Timber.Events.ErrorEventTest do
  use Timber.TestCase

  alias Timber.Events.ErrorEvent

  describe "Timber.Events.ErrorEvent.new/1" do
    test "converting to an ErrorEvent" do
      log_message =
        """
        ** (exit) an exception was raised:
            ** (RuntimeError) boom
                (my_app) web/controllers/page_controller.ex:5: MyApp.PageController.index/2
                (my_app) web/controllers/page_controller.ex:1: MyApp.PageController.action/2
                (my_app) web/controllers/page_controller.ex:1: MyApp.PageController.phoenix_controller_pipeline/2
                (my_app) lib/my_app/endpoint.ex:1: MyApp.Endpoint.instrument/4
                (my_app) lib/phoenix/router.ex:261: MyApp.Router.dispatch/2
                (my_app) web/router.ex:1: MyApp.Router.do_call/2
                (my_app) lib/plug/error_handler.ex:64: MyApp.Router.call/2
                (my_app) lib/my_app/endpoint.ex:1: MyApp.Endpoint.phoenix_pipeline/1
                (my_app) lib/my_app/endpoint.ex:1: MyApp.Endpoint.call/2
                (plug) lib/plug/adapters/cowboy/handler.ex:15: Plug.Adapters.Cowboy.Handler.upgrade/4
                (cowboy) /Users/benjohnson/Code/timber/odin/deps/cowboy/src/cowboy_protocol.erl:442: :cowboy_protocol.execute/4
        """
      {:ok, event} = ErrorEvent.new(log_message)
      assert event == %Timber.Events.ErrorEvent{
        message: "boom",
        name: "RuntimeError",
        backtrace: [
          %{app_name: "my_app", file: "web/controllers/page_controller.ex", function: "MyApp.PageController.index/2", line: 5},
          %{app_name: "my_app", file: "web/controllers/page_controller.ex", function: "MyApp.PageController.action/2", line: 1},
          %{app_name: "my_app", file: "web/controllers/page_controller.ex", function: "MyApp.PageController.phoenix_controller_pipeline/2", line: 1},
          %{app_name: "my_app", file: "lib/my_app/endpoint.ex", function: "MyApp.Endpoint.instrument/4", line: 1},
          %{app_name: "my_app", file: "lib/phoenix/router.ex", function: "MyApp.Router.dispatch/2", line: 261},
          %{app_name: "my_app", file: "web/router.ex", function: "MyApp.Router.do_call/2", line: 1},
          %{app_name: "my_app", file: "lib/plug/error_handler.ex", function: "MyApp.Router.call/2", line: 64},
          %{app_name: "my_app", file: "lib/my_app/endpoint.ex", function: "MyApp.Endpoint.phoenix_pipeline/1", line: 1},
          %{app_name: "my_app", file: "lib/my_app/endpoint.ex", function: "MyApp.Endpoint.call/2", line: 1},
          %{app_name: "plug", file: "lib/plug/adapters/cowboy/handler.ex", function: "Plug.Adapters.Cowboy.Handler.upgrade/4", line: 15}
        ]
      }
    end

    test "native functions" do
      log_message =
        """
        ** (exit) an exception was raised:
            ** (ArgumentError) argument error
                (stdlib) :ets.lookup(:noproc, 111)
        """
      result = ErrorEvent.new(log_message)
      assert result == {:error, :could_not_parse_message}
    end

    test "malformed stacktrace" do
      log_message =
        """
        ** (exit) an exception was raised:
            ** (RuntimeError) boom
                (my_app) malformed
        """
      result = ErrorEvent.new(log_message)
      assert result == {:error, :could_not_parse_message}
    end

    test "malformed message" do
      {:error, :could_not_parse_message} = ErrorEvent.new("testing")
    end
  end
end