defmodule Mix.Tasks.Timber.Install.ConfigFileTest do
  use Timber.TestCase

  alias Mix.Tasks.Timber.Install.{Application, ConfigFile}
  alias Timber.Installer.{FakeFile, FakeIO}

  describe "Mix.Tasks.Timber.Install.ConfigFile.create!/1" do
    test "without an endpoint_module_name" do
      FakeFile.stub(:open, fn
        "config/timber.exs" = file_path, [:write] -> {:ok, "#{file_path} device"}
      end)

      FakeIO.stub(:binwrite, fn "config/timber.exs device", file_contents ->
          refute file_contents =~ "config :timber_elixir, TimberElixir.Endpoint"
          :ok
      end)

      FakeFile.stub(:close, fn "config/timber.exs device" -> :ok end)

      application = build_application()
      application = %{application | endpoint_module_name: nil}
      result = ConfigFile.create!(application)
      assert result == :ok
    end

    test "without an repo_module_name" do
      FakeFile.stub(:open, fn
        "config/timber.exs" = file_path, [:write] -> {:ok, "#{file_path} device"}
      end)

      FakeIO.stub(:binwrite, fn "config/timber.exs device", file_contents ->
        refute file_contents =~ "config :timber_elixir, TimberElixir.Repo"
        :ok
      end)

      FakeFile.stub(:close, fn "config/timber.exs device" -> :ok end)

      application = build_application()
      application = %{application | repo_module_name: nil}
      result = ConfigFile.create!(application)
      assert result == :ok
    end

    test "with all module names" do
      FakeFile.stub(:open, fn
        "config/timber.exs" = file_path, [:write] -> {:ok, "#{file_path} device"}
      end)

      expected_file_contents =
        """
        use Mix.Config

        # Update the instrumenters so that we can structure Phoenix logs
        config :timber_elixir, TimberElixir.Endpoint,
          instrumenters: [Timber.Integrations.PhoenixInstrumenter]

        # Structure Ecto logs
        config :timber_elixir, TimberElixir.Repo,
          loggers: [{Timber.Integrations.EctoLogger, :log, [:info]}]

        # Use Timber as the logger backend
        # Feel free to add additional backends if you want to send you logs to multiple devices.
        config :logger,
          backends: [Timber.LoggerBackend]

        # Direct logs to STDOUT for Heroku. We'll use Heroku drains to deliver logs.
        config :timber,
          transport: Timber.Transports.IODevice

        # For dev / test environments, always log to STDOUt and format the logs properly
        if Mix.env() == :dev || Mix.env() == :test do
          config :timber, transport: Timber.Transports.IODevice

          config :timber, :io_device,
            colorize: true,
            format: :logfmt,
            print_timestamps: true,
            print_log_level: true,
            print_metadata: false # turn this on to view the additiional metadata
        end

        # Need help?
        # Email us: support@timber.io
        # File an issue: https://github.com/timberio/timber-elixir/issues
        """

      FakeIO.stub(:binwrite, fn
        "config/timber.exs device", ^expected_file_contents -> :ok
      end)

      FakeFile.stub(:close, fn "config/timber.exs device" -> :ok end)

      application = build_application()
      result = ConfigFile.create!(application)
      assert result == :ok
    end
  end

  defp build_application do
    %Application{api_key: "api_key",
      config_file_path: "config/config.exs",
      endpoint_file_path: "lib/timber_elixir/endpoint.ex",
      endpoint_module_name: "TimberElixir.Endpoint",
      heroku_drain_url: "drain_url", mix_name: "timber_elixir",
      module_name: "TimberElixir", name: "Timber",
      platform_type: "heroku",
      repo_file_path: "lib/timber_elixir/repo.ex",
      repo_module_name: "TimberElixir.Repo", slug: "timber",
      web_file_path: "web/web.ex"}
  end
end