defmodule Mix.Tasks.Timber.InstallTest do
  use Timber.TestCase

  alias Mix.Tasks.Timber.Install
  alias Timber.{FakeFile, FakeIO, FakePath, InstallerFileContents}

  describe "Mix.Tasks.Timber.Install.run/1" do
    test "without an API key" do
      Install.run([])
      [puts_call] = FakeIO.get_puts_calls()
      assert puts_call =! "Uh oh! You forgot to include your API key."
    end

    test "end-to-end success" do
      FakePath.stub(:wildcard, fn
        "config/config.exs" = file_path -> [file_path]
        "lib/*/endpoint.ex" = file_path -> ["lib/my_app/endpoint.ex"]
        "web/web.ex" = file_path -> [file_path]
      end)

      FakeFile.stub(:open, fn
        "config/timber.exs" = file_path, [:write] -> {:ok, "#{file_path} device"}
        "config/config.exs" = file_path, [:append] -> {:ok, "#{file_path} device"}
        "lib/my_app/endpoint.ex" = file_path, [:write] -> {:ok, "#{file_path} device"}
        "web/web.ex" = file_path, [:write] -> {:ok, "#{file_path} device"}
      end)

      timber_config_contents = InstallerFileContents.timber_config_contents()
      config_addition = InstallerFileContents.config_addition()
      new_endpoint_contents = InstallerFileContents.new_endpoint_contents()
      new_web_contents = InstallerFileContents.new_web_contents()

      FakeIO.stub(:binwrite, fn
        "config/timber.exs device", ^timber_config_contents -> :ok
        "config/config.exs device", ^config_addition -> :ok
        "lib/my_app/endpoint.ex device", ^new_endpoint_contents -> :ok
        "web/web.ex device", ^new_web_contents -> :ok
      end)

      FakeFile.stub(:close, fn
        "config/timber.exs device" -> :ok
        "config/config.exs device" -> :ok
        "lib/my_app/endpoint.ex device" -> :ok
        "web/web.ex device" -> :ok
      end)

      FakeFile.stub(:read, fn
        "config/config.exs" = file_path -> {:ok, InstallerFileContents.default_config_contents()}
        "lib/my_app/endpoint.ex" = file_path -> {:ok, InstallerFileContents.default_endpoint_contents()}
        "web/web.ex" = file_path -> {:ok, InstallerFileContents.default_web_contents()}
      end)

      FakeIO.stub(:gets, fn
        "Does your application have user accounts? (y/n): " -> "y"
        "Ready to proceed? (y/n): " -> "y"
        "How would rate this install experience? 1 (bad) - 5 (perfect): " -> "5"
      end)

      Install.run(["api_key"])

      expected_output =  "🌲 Timber installation\n--------------------------------------------------------------------------------\nWebsite:       https://timber.io\nDocumentation: http://timber.io/docs\nSupport:       support@timber.io\n--------------------------------------------------------------------------------\n\nThis installer will walk you through setting up Timber in your application.\nAt the end we'll make sure logs are flowing properly.\nGrab your axe!\n\nCreating config/timber.exs............................................\e[32m✓ Success!\n\e[0mLinking config/timber.exs in config/config.exs........................\e[32m✓ Success!\n\e[0mAdding Timber plugs to lib/my_app/endpoint.ex.........................\e[32m✓ Success!\n\e[0mDisabling default Phoenix logging web/web.ex..........................\e[32m✓ Success!\n\e[0m\n--------------------------------------------------------------------------------\n\n\nGreat! Timber can add user context to your logs, allowing you to search\nand tail logs for specific users. To install this, please add this\ncode wherever you authenticate your user. Typically in a plug:\n\n    %Timber.Contexts.UserContext{id: id, name: name, email: email}\n    |> Timber.add_context()\n\n\n--------------------------------------------------------------------------------\n\nNow we need to send your logs to the Timber service.\nPlease run this command in a separate terminal and return when complete:\n\n    heroku drains:add url\n\n\r\e[2KWaiting for logs (this can sometimes take a minute)\e[u\e[0m\r\e[2KWaiting for logs (this can sometimes take a minute).\e[u\e[0m\r\e[2KWaiting for logs (this can sometimes take a minute)..\e[u\e[0m\r\e[2KWaiting for logs (this can sometimes take a minute)...\e[u\e[0m\r\e[2KWaiting for logs (this can sometimes take a minute)\e[u\e[0m\r\e[2KWaiting for logs (this can sometimes take a minute).\e[u\e[0m\r\e[2KWaiting for logs (this can sometimes take a minute)..\e[u\e[0m\r\e[2KWaiting for logs (this can sometimes take a minute)...\e[u\e[0m\r\e[2KWaiting for logs (this can sometimes take a minute)\e[u\e[0m\r\e[2KWaiting for logs (this can sometimes take a minute).\e[u\e[0m\e[32m✓ Success!\n\e[0m\n--------------------------------------------------------------------------------\n\nDone! 🎉\n\n* Your Timber console URL: https://app.timber.io\n* Get ✨100mb✨ for starring our repo: https://github.com/timberio/timber-elixir\n* Get ✨50mb✨ for following @timberdotio on twitter\n* Get ✨250mb✨ for tweeting your experience to @timberdotio\n\n(your account will be credited within 2-3 business days)\n\n💖 We love you too! Let's get to loggin' 🌲\n"

      output = FakeIO.get_output()

      raise inspect(output)
      assert output == expected_output
    end
  end
end