defmodule Mix.Tasks.Timber.Install.ConfigFileTest do
  use Timber.TestCase

  alias Mix.Tasks.Timber.Install.{API, Application, ConfigFile}
  alias Timber.Installer.{FakeFile, FakeHTTPClient, FakeIO}

  describe "Mix.Tasks.Timber.Install.ConfigFile.create!/1" do
    # test "without an endpoint_module_name" do
    #   FakeFile.stub(:open, fn
    #     "config/timber.exs" = file_path, [:write] -> {:ok, "#{file_path} device"}
    #   end)

    #   FakeIO.stub(:binwrite, fn "config/timber.exs device", file_contents ->
    #       refute file_contents =~ "config :timber_elixir, TimberElixir.Endpoint"
    #       :ok
    #   end)

    #   FakeFile.stub(:close, fn "config/timber.exs device" -> :ok end)

    #   FakeHTTPClient.stub(:request, fn
    #     :post, [{'Authorization', 'Basic YXBpX2tleQ=='}, {'X-Installer-Session-Id', _session_id}], "https://api.timber.io/installer/events", _opts ->
    #       {:ok, 204, ""}
    #   end)

    #   api = %API{api_key: "api_key", session_id: "session_id"}

    #   application = build_application()
    #   application = %{application | endpoint_module_name: nil}
    #   result = ConfigFile.create!(application, api)
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
    #   result = ConfigFile.create!(application, api)
    #   assert result == :ok
    # end

    test "with all module names" do
      FakeFile.stub(:open, fn
        "config/timber.exs" = file_path, [:write] -> {:ok, "#{file_path} device"}
      end)

      expected_file_contents =
        """
        use Mix.Config

        # Use Timber as the logger backend
        # Feel free to add additional backends if you want to send you logs to multiple devices.
        # For Heroku, use the `:console` backend provided with Logger but customize
        # it to use Timber's internal formatting system
        config :logger,
          backends: [:console],
          format: {Timber.Formatter, :format},
          metadata: [:timber_context, :event],
          utc_log: true

        # For dev / test environments, always log to STDOUt and format the logs properly
        if Mix.env() == :dev || Mix.env() == :test do
          # Fall back to the default `:console` backend with the Timber custom formatter
          config :logger,
            backends: [:console],
            format: {Timber.Formatter, :format},
            metadata: [:timber_context, :event],
            utc_log: true

          config :timber, Timber.Formatter,
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

      FakeIO.stub(:binwrite, fn "config/timber.exs device", content ->
        assert content == expected_file_contents
        :ok
      end)

      FakeFile.stub(:close, fn "config/timber.exs device" -> :ok end)

      FakeHTTPClient.stub(:request, fn
        :post, [{'Authorization', 'Basic YXBpX2tleQ=='}, {'X-Installer-Session-Id', _session_id}], "https://api.timber.io/installer/events", _opts ->
          {:ok, 204, ""}
      end)

      api = %API{api_key: "api_key", session_id: "session_id"}

      application = build_application()
      result = ConfigFile.create!(application, api)
      assert result == :ok
    end
  end

  defp build_application do
    %Application{api_key: "api_key",
     heroku_drain_url: "drain_url", mix_name: "timber_elixir",
     module_name: "TimberElixir", name: "Timber",
     platform_type: "heroku", slug: "timber"}
  end
end
