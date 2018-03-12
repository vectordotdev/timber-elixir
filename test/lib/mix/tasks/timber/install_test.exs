defmodule Mix.Tasks.Timber.InstallTest do
  use Timber.TestCase

  alias Mix.Tasks.Timber.Install
  alias Timber.Installer.{FakeFile, FakeHTTPClient, FakeIO, FakeFileContents}

  describe "Mix.Tasks.Timber.Install.run/1" do
    test "without an API key" do
      Install.run([])
      output = FakeIO.get_output()
      assert output =~ "Welcome to Timber. In order to proceed, you'll need an API key."
    end

    if Code.ensure_loaded?(Phoenix) && Code.ensure_loaded?(Ecto) do
      # This test is absurd, but it's important this works properly, end-to-end.
      test "end-to-end success" do
        FakeFile.stub(:exists?, fn _file_path -> true end)

        FakeFile.stub(:open, fn
          "config/timber.exs" = file_path, [:write] -> {:ok, "#{file_path} device"}
          "config/config.exs" = file_path, [:append] -> {:ok, "#{file_path} device"}
          "{lib,web}/**/endpoint.ex" = file_path, [:write] -> {:ok, "#{file_path} device"}
          "{lib,web}/**/web.ex" = file_path, [:write] -> {:ok, "#{file_path} device"}
        end)

        timber_config_contents = FakeFileContents.timber_config_contents()
        config_addition = FakeFileContents.config_addition()
        new_endpoint_contents = FakeFileContents.new_endpoint_contents()
        new_web_contents = FakeFileContents.new_web_contents()

        FakeIO.stub(:binwrite, fn
          "config/timber.exs device", contents ->
            assert contents == timber_config_contents
            :ok

          "config/config.exs device", contents ->
            assert contents == config_addition
            :ok

          "{lib,web}/**/endpoint.ex device", contents ->
            assert contents == new_endpoint_contents
            :ok

          "{lib,web}/**/web.ex device", contents ->
            assert contents == new_web_contents
            :ok
        end)

        FakeFile.stub(:close, fn
          "config/timber.exs device" -> :ok
          "config/config.exs device" -> :ok
          "{lib,web}/**/endpoint.ex device" -> :ok
          "{lib,web}/**/web.ex device" -> :ok
        end)

        FakeFile.stub(:read, fn
          "config/config.exs" -> {:ok, FakeFileContents.default_config_contents()}
          "{lib,web}/**/endpoint.ex" -> {:ok, FakeFileContents.default_endpoint_contents()}
          "{lib,web}/**/repo.ex" -> {:ok, FakeFileContents.default_repo_contents()}
          "{lib,web}/**/web.ex" -> {:ok, FakeFileContents.default_web_contents()}
          path -> raise path
        end)

        FakeIO.stub(:gets, fn
          "Does your application have user accounts? (y/n): " -> "y"
          "Ready to proceed? (y/n): " -> "y"
          "How would rate this install experience? 1 (bad) - 5 (perfect): " -> "5"
        end)

        FakeHTTPClient.stub(:request, fn
          :get,
          [{'Authorization', 'Basic YXBpX2tleQ=='}, {'X-Installer-Session-Id', _session_id}],
          "https://api.timber.io/installer/application",
          [] ->
            {:ok, 200,
             "{\"data\": {\"slug\":\"timber\",\"platform_type\":\"heroku\",\"name\":\"Timber\",\"heroku_drain_url\":\"drain_url\",\"api_key\":\"api_key\"}}"}

          :post,
          [{'Authorization', 'Basic YXBpX2tleQ=='}, {'X-Installer-Session-Id', _session_id}],
          "https://api.timber.io/installer/events",
          _opts ->
            {:ok, 204, ""}

          :get,
          [{'Authorization', 'Basic YXBpX2tleQ=='}, {'X-Installer-Session-Id', __session_id}],
          "https://api.timber.io/installer/has_logs",
          [] ->
            {:ok, 204, ""}
        end)

        Install.run(["api_key"])

        expected_output =
          "\e[32m\n🌲 Timber.io Elixir Installer\n\n ^  ^  ^   ^      ___I_      ^  ^   ^  ^  ^   ^  ^\n/|\\/|\\/|\\ /|\\    /\\-_--\\    /|\\/|\\ /|\\/|\\/|\\ /|\\/|\\\n/|\\/|\\/|\\ /|\\   /  \\_-__\\   /|\\/|\\ /|\\/|\\/|\\ /|\\/|\\\n/|\\/|\\/|\\ /|\\   |[]| [] |   /|\\/|\\ /|\\/|\\/|\\ /|\\/|\\\n\e[0m\n--------------------------------------------------------------------------------\nWebsite:       https://timber.io\nDocumentation: https://timber.io/docs\nSupport:       support@timber.io\n--------------------------------------------------------------------------------\n\nCreating config/timber.exs............................................\e[32m✓ Success!\e[0m\nLinking config/timber.exs in config/config.exs........................\e[32m✓ Success!\e[0m\nAdding Timber plugs to {lib,web}/**/endpoint.ex.......................\e[32m✓ Success!\e[0m\nDisabling default Phoenix logging in {lib,web}/**/web.ex..............\e[32m✓ Success!\e[0m\n\n--------------------------------------------------------------------------------\n\nDoes your application have user accounts? (y/n): y\nGreat! Timber can add user context to your logs, allowing you to search\nand tail logs for specific users. To install this, please follow the\nappropraite instructions below:\n\n1. If you're using Guardian (an elixir authentication library), checkout\n   this gist: https://gist.github.com/binarylogic/50901f453587748c3d70295e49f5797a\n\n2. For everything else, simply add the following code immediately after\n   you load (or build) your user:\n\n\e[34m    %Timber.Contexts.UserContext{id: id, name: name, email: email}\n    |> Timber.add_context()\n\e[0m\n\nReady to proceed? (y/n): y\n--------------------------------------------------------------------------------\n\nChecking if your application is already sending logs..................\e[32m✓ Success!\e[0m\n\n--------------------------------------------------------------------------------\n\n\e[33m* Get ✨ 250mb✨ for tweeting your experience to @timberdotio\n* Get ✨ 100mb✨ for starring our repo: https://github.com/timberio/timber-elixir\n* Get ✨ 50mb✨ for following @timberdotio on twitter\n\e[0m\n(Your account will be credited within 2-3 business days.\n If you do not notice a credit please contact us: support@timber.io)\n\n--------------------------------------------------------------------------------\n\nLast step!\n\n    \e[34mgit add config/timber.exs\e[0m\n    \e[34mgit commit -am 'Install timber'\e[0m\n\nPush and deploy. 🚀\n\n--------------------------------------------------------------------------------\n\nHow would rate this install experience? 1 (bad) - 5 (perfect): 5\n💖  We love you too! Let's get to loggin' 🌲\n\n"

        output = FakeIO.get_output()

        assert output == expected_output
      end
    end
  end
end
