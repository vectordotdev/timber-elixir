defmodule Mix.Tasks.Timber.Install.TimberConfigFileTest do
  use Timber.TestCase

  alias Mix.Tasks.Timber.Install.{API, Application, Project, TimberConfigFile}
  alias Timber.Installer.{FakeFile, FakeHTTPClient, FakeIO}

  describe "Mix.Tasks.Timber.Install.TimberConfigFile.create!/1" do
    # test "Phoenix presence" do
    #   FakeFile.stub(:open, fn
    #     "config/timber.exs" = file_path, [:write] -> {:ok, "#{file_path} device"}
    #   end)

    #   FakeIO.stub(:binwrite, fn "config/timber.exs device", file_contents ->
    #     endppoint_check = file_contents =~ "config :timber_elixir, TimberElixir.Endpoint"
    #     if Code.ensure_loaded?(Phoenix) do
    #       assert endppoint_check
    #     else
    #       refute endppoint_check
    #     end
    #     :ok
    #   end)

    #   FakeFile.stub(:close, fn "config/timber.exs device" -> :ok end)

    #   FakeHTTPClient.stub(:request, fn
    #     :post, [{'Authorization', 'Basic YXBpX2tleQ=='}, {'X-Installer-Session-Id', _session_id}], "https://api.timber.io/installer/events", _opts ->
    #       {:ok, 204, ""}
    #   end)

    #   api = %API{api_key: "api_key", session_id: "session_id"}

    #   application = build_application()
    #   result = TimberConfigFile.create!(application, api)
    #   assert result == :ok
    # end

    # test "without an repo_module_name" do
    #   FakeFile.stub(:open, fn
    #     "config/timber.exs" = file_path, [:write] -> {:ok, "#{file_path} device"}
    #   end)

    #   FakeIO.stub(:binwrite, fn "config/timber.exs device", file_contents ->
    #     refute file_contents =~ "config :timber_elixir, TimberElixir.Repo"
    #     :ok
    #   end)

    #   FakeFile.stub(:close, fn "config/timber.exs device" -> :ok end)

    #   FakeHTTPClient.stub(:request, fn
    #     :post, [{'Authorization', 'Basic YXBpX2tleQ=='}, {'X-Installer-Session-Id', _session_id}], "https://api.timber.io/installer/events", _opts ->
    #       {:ok, 204, ""}
    #   end)

    #   api = %API{api_key: "api_key", session_id: "session_id"}

    #   application = build_application()
    #   application = %{application | repo_module_name: nil}
    #   result = TimberConfigFile.create!(application, api)
    #   assert result == :ok
    # end

    test "with all module names" do
      FakeFile.stub(:open, fn
        "config/timber.exs" = file_path, [:write] -> {:ok, "#{file_path} device"}
      end)

      expected_file_contents =
        """
        use Mix.Config

        # Update the instrumenters so that we can structure Phoenix logs
        config :my_project, MyEndpointModule,
          instrumenters: [Timber.Integrations.PhoenixInstrumenter]

        # Structure Ecto logs
        config :my_project, MyRepoModule,
          loggers: [{Timber.Integrations.EctoLogger, :log, [:info]}]

        # Use Timber as the logger backend
        # Feel free to add additional backends if you want to send you logs to multiple devices.
        # For Heroku, use the `:console` backend provided with Logger but customize
        # it to use Timber's internal formatting system
        config :logger,
          backends: [:console],
          utc_log: true

        config :logger, :console,
          format: {Timber.Formatter, :format},
          metadata: [:timber_context, :event, :application, :file, :function, :line, :module]

        # For the following environments, do not log to the Timber service. Instead, log to STDOUT
        # and format the logs properly so they are human readable.
        environments_to_exclude = [:dev, :test]
        if Enum.member?(environments_to_exclude, Mix.env()) do
          # Fall back to the default `:console` backend with the Timber custom formatter
          config :logger,
            backends: [:console],
            utc_log: true

          config :logger, :console,
            format: {Timber.Formatter, :format},
            metadata: [:timber_context, :event, :application, :file, :function, :line, :module]

          config :timber, Timber.Formatter,
            colorize: true,
            format: :logfmt,
            print_timestamps: true,
            print_log_level: true,
            print_metadata: false # turn this on to view the additiional metadata
        end

        # Need help?
        # Email us: support@timber.io
        # Or, file an issue: https://github.com/timberio/timber-elixir/issues
        """

      FakeIO.stub(:binwrite, fn "config/timber.exs device", contents ->
        assert contents == expected_file_contents
        :ok
      end)

      FakeFile.stub(:close, fn "config/timber.exs device" -> :ok end)

      FakeHTTPClient.stub(:request, fn
        :post, [{'Authorization', 'Basic YXBpX2tleQ=='}, {'X-Installer-Session-Id', _session_id}], "https://api.timber.io/installer/events", _opts ->
          {:ok, 204, ""}
      end)

      project = %Project{endpoint_module_name: "MyEndpointModule", mix_name: "my_project", repo_module_name: "MyRepoModule"}
      api = %API{api_key: "api_key", session_id: "session_id"}

      application = build_application()
      result = TimberConfigFile.create!(application, project, api)
      assert result == :ok
    end
  end

  defp build_application do
    %Application{api_key: "api_key",
     heroku_drain_url: "drain_url", name: "Timber",
     platform_type: "heroku", slug: "timber"}
  end
end
