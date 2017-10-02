if Code.ensure_loaded?(Phoenix) do
  defmodule Timber.Integrations.PhoenixInstrumenterTest do
    # This test case has to be asynchronous since it modifies and depends on
    # the application environment which is global
    use Timber.TestCase, async: false

    import ExUnit.CaptureLog

    alias Timber.Integrations.PhoenixInstrumenter

    require Logger

    setup do
      env = Application.get_env(:timber, PhoenixInstrumenter, [])

      on_exit fn ->
        # Restore the saved environment
        Application.put_env(:timber, PhoenixInstrumenter, env)
      end

      {:ok, env: env}
    end

    describe "Timber.Integrations.PhoenixInstrumenter.get_unparsed_blacklist/0" do
      test "fetches the unparsed blacklist from the Application environment" do
        blacklist = [
          {A, :action},
          {B, :action}
        ]

        Application.put_env(:timber, PhoenixInstrumenter, [{:controller_actions_blacklist, blacklist}])

        assert [{A, :action}, {B, :action}] = PhoenixInstrumenter.get_unparsed_blacklist()
      end
    end

    describe "Timber.Integrations.PhoenixInstrumenter.parse_blacklist/1" do
      test "parses blacklist" do
        unparsed_blacklist = [
          {A, :action},
          {B, :action}
        ]

        parsed_blacklist = PhoenixInstrumenter.parse_blacklist(unparsed_blacklist)

        assert MapSet.member?(parsed_blacklist, {A, :action})
        assert MapSet.member?(parsed_blacklist, {B, :action})
        refute MapSet.member?(parsed_blacklist, {Controller, :action})
      end
    end

    describe "Timber.Integrations.PhoenixInstrumenter.add_controller_action_to_blacklist/2" do
      test "adds controller action to the blacklist" do
        PhoenixInstrumenter.put_parsed_blacklist(MapSet.new([
          {A, :action},
          {B, :action}
        ]))

        PhoenixInstrumenter.add_controller_action_to_blacklist(Controller, :action)
        blacklist = PhoenixInstrumenter.get_parsed_blacklist()

        assert PhoenixInstrumenter.controller_action_blacklisted?({A, :action}, blacklist)
        assert PhoenixInstrumenter.controller_action_blacklisted?({B, :action}, blacklist)
        assert PhoenixInstrumenter.controller_action_blacklisted?({Controller, :action}, blacklist)
      end
    end

    describe "Timber.Integrations.PhoenixInstrumenter.remove_controller_action_from_blacklist/2" do
      test "removes controller action from blacklist" do
        PhoenixInstrumenter.put_parsed_blacklist(MapSet.new([
          {A, :action},
          {B, :action}
        ]))

        PhoenixInstrumenter.remove_controller_action_from_blacklist(B, :action)

        blacklist = PhoenixInstrumenter.get_parsed_blacklist()

        assert PhoenixInstrumenter.controller_action_blacklisted?({A, :action}, blacklist)
        refute PhoenixInstrumenter.controller_action_blacklisted?({B, :action}, blacklist)
      end
    end

    describe "Timber.Integrations.PhoenixInstrumenter.get_parsed_blacklist/0" do
      test "retrieves empty MapSet when blacklist is not in application environment" do
        :ok = Application.put_env(:timber, PhoenixInstrumenter, [])
        blacklist = PhoenixInstrumenter.get_parsed_blacklist()
        assert match?(%MapSet{}, blacklist)
      end

      test "retrieves the blacklist from the application environment", %{env: env} do
        blacklist = MapSet.new([
          {A, :action},
          {B, :action}
        ])

        new_env = Keyword.put(env, :parsed_controller_actions_blacklist, blacklist)
        :ok = Application.put_env(:timber, PhoenixInstrumenter, new_env)

        ^blacklist = PhoenixInstrumenter.get_parsed_blacklist()
      end
    end

    describe "Timber.Integrations.PhoenixInstrumenter.put_parsed_blacklist/1" do
      test "puts the blacklist in the application environment" do
        blacklist = MapSet.new([
          {A, :action},
          {B, :action}
        ])

        PhoenixInstrumenter.put_parsed_blacklist(blacklist)

        new_env = Application.get_env(:timber, PhoenixInstrumenter, [])
        ^blacklist = Keyword.get(new_env, :parsed_controller_actions_blacklist, [])
      end
    end

    describe "Timber.Integrations.PhoenixInstrumenter.phoenix_channel_join/3" do
      test "logs phoenix_channel_join as configured by the channel" do
        log = capture_log(fn ->
          socket = %Phoenix.Socket{channel: :channel, topic: "topic"}
          PhoenixInstrumenter.phoenix_channel_join(:start, %{}, %{socket: socket, params: %{key: "val"}})
        end)
        assert log =~ "Joined channel channel with \"topic\" @metadata "
      end
    end

    describe "Timber.Integrations.PhoenixInstrumenter.phoenix_channel_receive/3" do
      test "logs phoenix_channel_receive as configured by the channel" do
        log = capture_log(fn ->
          socket = %Phoenix.Socket{channel: :channel, topic: "topic"}
          PhoenixInstrumenter.phoenix_channel_receive(:start, %{}, %{socket: socket, event: "e", params: %{}})
        end)
        assert log =~ "Received e on \"topic\" to channel @metadata "
      end
    end

    describe "Timber.Integrations.PhoenixInstrumenter.phoenix_controller_call/3" do
      test "logs phoenix controller calls" do
        controller = Controller
        action = :action
        conn =
          Phoenix.ConnTest.build_conn()
          |> Plug.Conn.put_private(:phoenix_controller, controller)
          |> Plug.Conn.put_private(:phoenix_action, action)

        log = capture_log(fn ->
          PhoenixInstrumenter.phoenix_controller_call(:start, %{}, %{conn: conn})
        end)

        assert log =~ "Processing with Controller.action/2"
      end

      test "does not log controller calls if the controller/action pair is in the black list" do
        controller = Controller
        action = :action

        PhoenixInstrumenter.add_controller_action_to_blacklist(controller, action)

        conn =
          Phoenix.ConnTest.build_conn()
          |> Plug.Conn.put_private(:phoenix_controller, controller)
          |> Plug.Conn.put_private(:phoenix_action, action)

        log = capture_log(fn ->
          PhoenixInstrumenter.phoenix_controller_call(:start, %{}, %{conn: conn})
        end)

        assert log == ""
      end
    end

    describe "Timber.Integrations.PhoenixInstrumenter.phoenix_controller_render/3" do
      test ":start returns the log level and template name by default" do
        controller = Controller
        action = :action
        template_name = "index.html"

        conn =
          Phoenix.ConnTest.build_conn()
          |> Plug.Conn.put_private(:phoenix_controller, controller)
          |> Plug.Conn.put_private(:phoenix_action, action)

        assert {:ok, :info, ^template_name} =
          PhoenixInstrumenter.phoenix_controller_render(:start, %{}, %{template: template_name, conn: conn})
      end

      test ":start returns true when the controller/action is not available" do
        # This test situation occurs when the route cannot be matched, for example
        template_name = "404.html"

        conn = Phoenix.ConnTest.build_conn()

        assert {:ok, :info, ^template_name} =
          PhoenixInstrumenter.phoenix_controller_render(:start, %{}, %{template: template_name, conn: conn})
      end

      test ":start returns false when the controller/action is blacklisted" do
        controller = Controller
        action = :action
        template_name = "index.html"

        PhoenixInstrumenter.add_controller_action_to_blacklist(controller, action)

        conn =
          Phoenix.ConnTest.build_conn()
          |> Plug.Conn.put_private(:phoenix_controller, controller)
          |> Plug.Conn.put_private(:phoenix_action, action)

        assert false == PhoenixInstrumenter.phoenix_controller_render(:start, %{}, %{template: template_name, conn: conn})
      end

      test ":start returns true when a template name is given but no connection" do
        # This test situation occurs when the route cannot be matched, for example
        template_name = "404.html"

        assert {:ok, :info, ^template_name} =
          PhoenixInstrumenter.phoenix_controller_render(:start, %{}, %{template: template_name})
      end

      test ":start returns :ok when an unsupported map is passed" do
        assert :ok = PhoenixInstrumenter.phoenix_controller_render(:start, %{}, %{})
      end

      test ":stop does not log anything when the third param is :ok" do
        log = capture_log(fn ->
          PhoenixInstrumenter.phoenix_controller_render(:stop, %{}, :ok)
        end)

        assert log == ""
      end

      test ":stop does not log anything when the third param is false" do
        log = capture_log(fn ->
          PhoenixInstrumenter.phoenix_controller_render(:stop, %{}, false)
        end)

        assert log == ""
      end

      test ":stop logs the render time when it is present" do
        template_name = "index.html"
        log_level = :info

        log = capture_log(fn ->
          PhoenixInstrumenter.phoenix_controller_render(:stop, 0, {:ok, log_level, template_name})
        end)

        assert log =~ "Rendered \"index.html\" in 0.0ms"
      end
    end
  end
end
