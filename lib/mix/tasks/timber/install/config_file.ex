defmodule Mix.Tasks.Timber.Install.ConfigFile do
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
            instrumenters: new_instrumenters
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
      config :logger,
        backends: [Timber.LoggerBackend]

      #{timber_portion(application)}
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

      # Need help? Contact us at support@timber.io
      """

    FileHelper.write!(@file_path, contents)
  end

  defp timber_portion(%{platform_type: "heroku"}) do
    """
    # Direct logs to STDOUT for Heroku. We'll use Heroku drains to deliver logs.
    config :timber,
      transport: Timber.Transports.IODevice
    """
  end

  defp timber_portion(%{api_key: api_key}) do
    """
    # Deliver logs via HTTP to the Timber API
    config :timber,
      transport: Timber.Transports.HTTP,
      api_key: #{api_key_portion(api_key)},
      http_client: Timber.Transports.HTTP.HackneyClient
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

    FileHelper.append_once!(config_file_path, contents)
  end
end