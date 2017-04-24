defmodule Mix.Tasks.Timber.Install.TimberConfigFile do
  @moduledoc false

  alias Mix.Tasks.Timber.Install.{FileHelper, IOHelper}

  @file_name "timber.exs"
  @file_path Path.join(["config", @file_name])

  # Adds the config/timber.exs file to be linked in config/config.exs
  def create!(application, project, api) do
    contents =
      """
      use Mix.Config
      #{endpoint_portion(project)}#{repo_portion(project)}
      # Use Timber as the logger backend
      # Feel free to add additional backends if you want to send you logs to multiple devices.
      #{timber_portion(application, api)}
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

    FileHelper.write!(@file_path, contents, api)
  end

  defp endpoint_portion(%{endpoint_module_name: nil}), do: ""

  defp endpoint_portion(%{mix_name: mix_name, endpoint_module_name: endpoint_module_name}) do
    """

    # Update the instrumenters so that we can structure Phoenix logs
    config :#{mix_name}, #{endpoint_module_name},
      instrumenters: [Timber.Integrations.PhoenixInstrumenter]
    """
  end

  defp repo_portion(%{repo_module_name: nil}), do: ""

  defp repo_portion(%{mix_name: mix_name, repo_module_name: repo_module_name}) do
    """

    # Structure Ecto logs
    config :#{mix_name}, #{repo_module_name},
      loggers: [{Timber.Integrations.EctoLogger, :log, [:info]}]
    """
  end

  defp timber_portion(%{platform_type: "heroku"}, _api) do
    """
    # For Heroku, use the `:console` backend provided with Logger but customize
    # it to use Timber's internal formatting system
    config :logger,
      backends: [:console],
      utc_log: true

    config :logger, :console,
      format: {Timber.Formatter, :format},
      metadata: [:timber_context, :event, :application, :file, :function, :line, :module]
    """
  end

  defp timber_portion(_application, api) do
    """
    # Deliver logs via HTTP to the Timber API by using the Timber HTTP backend.
    config :logger,
      backends: [Timber.LoggerBackends.HTTP],
      utc_log: true

    config :timber,
      api_key: #{api_key_portion(api)}
    """
  end

  defp api_key_portion(%{api_key: api_key} = api) do
    """
    How would you prefer to store your Timber API key?

    1) In the TIMBER_LOGS_KEY environment variable
    2) Inline within the #{@file_path} file
    """
    |> IOHelper.puts()

    case IOHelper.ask("Enter your choice (1/2)", api) do
      "1" -> "{:system, \"TIMBER_LOGS_KEY\"}"
      "2" -> "\"#{api_key}\""

      other ->
        "Sorry #{inspect(other)} is not a valid input. Please try again."
        |> IOHelper.puts(:red)
        api_key_portion(api)
    end
  end

  def file_path, do: @file_path

  def link!(config_file_path, api) do
    contents =
      """

      # Import Timber, structured logging
      import_config \"#{@file_name}\"
      """

    check = "import_config \"#{@file_name}\""

    FileHelper.append_once!(config_file_path, contents, check, api)
  end
end
