defmodule Mix.Tasks.Timber.InstallTest do
  use Timber.TestCase

  alias Mix.Tasks.Timber.Install
  alias Timber.Installer.{FakeFile, FakeHTTPClient, FakeIO, FakeFileContents}

  describe "Mix.Tasks.Timber.Install.run/1" do
    test "without an API key" do
      Install.run([])
      output = FakeIO.get_output()
      assert output =~ "Uh oh! You forgot to include your API key."
    end

    # This test is absurd, but it's important this works properly, end-to-end.
    test "end-to-end success" do
      FakeFile.stub(:exists?, fn _file_path -> true end)

      FakeFile.stub(:open, fn
        "config/timber.exs" = file_path, [:write] -> {:ok, "#{file_path} device"}
        "config/config.exs" = file_path, [:append] -> {:ok, "#{file_path} device"}
        "lib/timber_elixir/endpoint.ex" = file_path, [:write] -> {:ok, "#{file_path} device"}
        "web/web.ex" = file_path, [:write] -> {:ok, "#{file_path} device"}
      end)

      timber_config_contents = FakeFileContents.timber_config_contents()
      config_addition = FakeFileContents.config_addition()
      new_endpoint_contents = FakeFileContents.new_endpoint_contents()
      new_web_contents = FakeFileContents.new_web_contents()

      FakeIO.stub(:binwrite, fn
        "config/timber.exs device", ^timber_config_contents -> :ok
        "config/config.exs device", ^config_addition -> :ok
        "lib/timber_elixir/endpoint.ex device", ^new_endpoint_contents -> :ok
        "web/web.ex device", ^new_web_contents -> :ok
      end)

      FakeFile.stub(:close, fn
        "config/timber.exs device" -> :ok
        "config/config.exs device" -> :ok
        "lib/timber_elixir/endpoint.ex device" -> :ok
        "web/web.ex device" -> :ok
      end)

      FakeFile.stub(:read, fn
        "config/config.exs" -> {:ok, FakeFileContents.default_config_contents()}
        "lib/timber_elixir/endpoint.ex" -> {:ok, FakeFileContents.default_endpoint_contents()}
        "web/web.ex" -> {:ok, FakeFileContents.default_web_contents()}
      end)

      FakeIO.stub(:gets, fn
        "Does your application have user accounts? (y/n): " -> "y"
        "Ready to proceed? (y/n): " -> "y"
        "How would rate this install experience? 1 (bad) - 5 (perfect): " -> "5"
      end)

      FakeHTTPClient.stub(:request!, fn
        _session_id, :get, "/installer/application", [api_key: "api_key"] ->
          {200, %{"api_key" => "api_key", "heroku_drain_url" => "drain_url", "name" => "Timber",
            "platform_type" => "heroku", "slug" => "timber"}}
        _session_id, :post, "/installer/events", [api_key: "api_key", body: _body] ->
          {204, ""}
        _session_id, :get, "/installer/has_logs", [api_key: "api_key"] ->
          {204, ""}
      end)

      Install.run(["api_key"])

      expected_output = "🌲 Timber installation\n--------------------------------------------------------------------------------\nWebsite:       https://timber.io\nDocumentation: https://timber.io/docs\nSupport:       support@timber.io\n--------------------------------------------------------------------------------\n\nThis installer will walk you through setting up Timber in your application.\nAt the end we'll make sure logs are flowing properly.\nGrab your axe!\n\n\nCreating config/timber.exs............................................\e[32m✓ Success!\e[0m\nLinking config/timber.exs in config/config.exs........................\e[32m✓ Success!\e[0m\nAdding Timber plugs to lib/timber_elixir/endpoint.ex..................\e[32m✓ Success!\e[0m\nDisabling default Phoenix logging web/web.ex..........................\e[32m✓ Success!\e[0m\n\n--------------------------------------------------------------------------------\n\nDoes your application have user accounts? (y/n): y\nGreat! Timber can add user context to your logs, allowing you to search\nand tail logs for specific users. To install this, please add this\ncode wherever you authenticate your user. Typically in a plug:\n\n    %Timber.Contexts.UserContext{id: id, name: name, email: email}\n    |> Timber.add_context()\n\nReady to proceed? (y/n): y\n--------------------------------------------------------------------------------\n\nNow we need to send your logs to the Timber service.\nPlease run this command in a separate terminal and return back here when complete:\n\n    heroku drains:add drain_url\n\n\r\e[2K\e[0mWaiting for logs (Heroku can sometimes take a minute).................\e[32m✓ Success!\e[0m\n\n--------------------------------------------------------------------------------\n\nDone! Commit these changes and deploy. 🎉\n\n* Timber URL: https://app.timber.io\n* Get ✨ 250mb✨ for tweeting your experience to @timberdotio\n* Get ✨ 100mb✨ for starring our repo: https://github.com/timberio/timber-elixir\n* Get ✨ 50mb✨ for following @timberdotio on twitter\n\n(Your account will be credited within 2-3 business days.\n If you do not notice a credit please contact us: support@timber.io)\n\nHow would rate this install experience? 1 (bad) - 5 (perfect): 5\n💖  We love you too! Let's get to loggin' 🌲\n\n"

      output = FakeIO.get_output()

      assert output == expected_output
    end
  end
end