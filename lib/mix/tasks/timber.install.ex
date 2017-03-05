defmodule Mix.Tasks.Timber.Install do
  use Mix.Task

  @pipe_tester Application.get_env(:timber, :pipe_tester, Timber.PipeTester)

  # Details
  @docs_url "http://timber.io/docs"
  @manual_installation_url "https://timber.io"
  @support_email "support@timber.io"
  @timber_config_file_name "timber.exs"
  @timber_config_file_path Path.join("config", @timber_config_file_name)
  @elixir_repo_url "https://github.com/timberio/timber-elixir"
  @twitter_handle "@timberdotio"
  @website_url "https://timber.io"

  # Messages
  @obtain_key_instructions_message "You can obtain your key by adding an application in https://app.timber.io, or by clicking 'edit' next to your application."
  @stuck_message "Still stuck? Shoot us an email: #{@support_email}"

  def run([]) do
    header_message()
    |> display()

    """
    Uh oh! You forgot to include your API key. Please specify it via:

        mix timber.install timber-application-api-key

    #{@obtain_key_instructions_message}

    #{@stuck_message}
    """
    |> warn_format()
    |> display()
  end

  def run([api_key]) do
    header_message()
    |> display()

    case validate_api_key(api_key) do
      :ok ->
        """
        This installer will walk you through setting up Timber in your application.
        At the end we'll send test logs to ensure everything is working properly.
        Grab your axe!
        """
        |> display()

        determine_transport()
        |> add_config_file()

        link_config_file()
        add_plugs()
        disable_phoenix_logging()
        test_the_pipes()


      {:error, reason} ->
        """
        Uh oh! It looks like the API key you provided is invalid :(
        Please sure that you copy the key properly.

        #{@obtain_key_instructions_message}

        #{@stuck_message}
        """
        |> display()
    end
  end

  defp validate_api_key(_), do: :ok

  defp determine_transport do
    """
    #{separator()}

    Which platform is your app hosted on?
    (this helps us determine how to transport your logs.)

    1) Heroku
    2) Other
    """
    |> display()

    prompt = "Enter your choice: (1/2)"
    case ask(prompt) do
      "1" -> :stdout
      "2" -> :http

      value ->
        """

        #{inspect(value)} is not a valid option. Please try again:
        """
        |> warn_format()
        |> display()

        """
        #{separator()}

        """
        |> display()

        determine_transport()
    end
  end

  defp add_config_file(transport_strategy) do
    contents =
      """
      use Mix.Config

      # Structure phoenix logs
      config :elixir_phoenix_example_app, ElixirPhoenixExampleApp.Endpoint,
        instrumenters: [Timber.Integrations.PhoenixInstrumenter]

      # Structure Ecto logs
      config :elixir_phoenix_example_app, ElixirPhoenixExampleApp.Repo,
        loggers: [{Timber.Integrations.EctoLogger, :log, [:info]}]

      # Use Timber as the logger backend
      config :logger,
        backends: [Timber.LoggerBackend]

      # Direct logs to STDOUT
      config :timber,
        transport: Timber.Transports.IODevice

      # Questions? Contact us at support@timber.io
      """

    print("\nCreating #{@timber_config_file_path}...")

    case File.open @timber_config_file_path, [:write] do
      {:ok, file} ->
        case IO.binwrite(file, contents) do
          :ok ->
            success_message()
            |> print()

          {:error, reason} ->
            IO.puts "Uh oh, we had a problem: #{reason}"
            exit :shutdown
        end
        File.close(file)

      {:error, reason} ->
        IO.puts "Uh oh, we had a problem: #{reason}"
        exit :shutdown
    end
  end

  defp link_config_file do
    print("\nLinking #{@timber_config_file_path} in #{@config_file_path}...")
    success_message()
    |> print()
  end

  defp add_plugs do
    print("\nAdding plugs to lib/myapp/endpoint.ex...")
    success_message()
    |> print()
  end

  defp disable_phoenix_logging do
    print("\nDisabling default Phoenix logging lib/myapp/endpoint.ex...")
    success_message()
    |> print()
  end

  defp test_the_pipes do
    print("\nTesting the pipes by sending a few test log messages:")
    success_message()
    |> print()
  end

  #
  # Messages
  #

  defp header_message do
    """
    🌲 Timber installation
    #{separator()}
    Website:       #{@website_url}
    Documentation: #{@docs_url}
    Support:       #{@support_email}
    #{separator()}
    """
  end

  defp manual_install_message do
    """
    No problem. Check out our manual installation guide at: #{@manual_installation_url}
    """
  end

  defp separator do
    "--------------------------------------------------------------------------------"
  end

  defp social_upgrades_message do
    """
    Get free data!
    --------------------------------------------------------------------------------
    If you enjoy using Timber, we'd love for you share your experience. And because
    we *love* our customers, we'll add free data to your account 🎉.

    * Get ✨100mb✨ for starring our repo: #{@elixir_repo_url}
    * Get ✨250mb✨ for tweeting your experience to #{@twitter_handle}
    """
  end

  defp success_message do
    IO.ANSI.format([:green, "✓ Success!"])
  end

  #
  # IO
  #

  defp ask(prompt) do
    input = String.trim(IO.gets("#{prompt}: "))
    if String.length(input) <= 0 do
      warn_format("Uh oh, we didn't receive an answer :(")
      |> display()
      ask(prompt)
    else
      input
    end
  end

  defp display(message), do: IO.puts(message)

  defp print(message), do: IO.write(message)

  defp warn_format(message) do
    IO.ANSI.format([:red, "⚠ ", message])
  end
end