defmodule Mix.Tasks.Timber.Install.ConfigFile do
  @moduledoc false

  alias Mix.Tasks.Timber.Install.{FileHelper, IOHelper}

  @file_name "timber.exs"
  @file_path Path.join(["config", @file_name])

  # Adds the config/timber.exs file to be linked in config/config.exs
  def create!(%{mix_name: mix_name, endpoint_module_name: endpoint_module_name,
    repo_module_name: repo_module_name} = application)
  do
    contents =
      """
      use Mix.Config
      """

    contents =
      if endpoint_module_name do
        contents <>
          """

          # Update the instrumenters so that we can structure Phoenix logs
          config :#{mix_name}, #{endpoint_module_name},
            instrumenters: [Timber.Integrations.PhoenixInstrumenter]
          """
      else
        contents
      end

    contents =
      if repo_module_name do
        contents <>
          """

          # Structure Ecto logs
          config :#{mix_name}, #{repo_module_name},
            loggers: [{Timber.Integrations.EctoLogger, :log, [:info]}]
          """
      else
        contents
      end

    contents = contents <>
      """

      # Use Timber as the logger backend
      # Feel free to add additional backends if you want to send you logs to multiple devices.
      #{timber_portion(application)}
      # For dev / test environments, always log to STDOUt and format the logs properly
      if Mix.env() == :dev || Mix.env() == :test do
        # Fall back to the default `:console` backend with the Timber custom formatter
        config :logger,
          backends: [:console],
          format: {Timber.Formatter, :format}

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

    FileHelper.write!(@file_path, contents)
  end

  defp timber_portion(%{platform_type: "heroku"}) do
    """
    # For Heroku, use the `:console` backend provided with Logger but customize
    # it to use Timber's internal formatting system
    config :logger,
      backends: [:console],
      format: {Timber.Formatter, :format}
    """
  end

  defp timber_portion(%{api_key: api_key}) do
    """
    # Deliver logs via HTTP to the Timber API by using the Timber HTTP backend.
    config :logger,
      backends: [Timber.LoggerBackends.HTTP]

    config :timber,
      api_key: #{api_key_portion(api_key)},
      http_client: Timber.HTTPClients.Hackney
    """
  end

  defp api_key_portion(api_key) do
    """
    How would you prefer to store your Timber API key?

    1) In the TIMBER_LOGS_KEY environment variable
    2) Inline within the #{@file_path} file
    """
    |> IOHelper.puts()

    case IOHelper.ask("Enter your choice (1/2)") do
      "1" -> "{:system, \"TIMBER_LOGS_KEY\"}"
      "2" -> "\"#{api_key}\""

      other ->
        "Sorry #{inspect(other)} is not a valid input. Please try again."
        |> IOHelper.puts(:red)
        api_key_portion(api_key)
    end
  end

  def file_path, do: @file_path

  def link!(config_file_path) do
    contents =
      """

      # Import Timber, structured logging
      import_config \"#{@file_name}\"
      """

    check = "import_config \"#{@file_name}\""

    FileHelper.append_once!(config_file_path, contents, check)
  end
end
