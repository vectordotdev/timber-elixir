defmodule Mix.Tasks.Timber.Install do
  use Mix.Task

  @nos ["n", "N", "No"]
  @pipe_tester Application.get_env(:timber, :pipe_tester, Timber.PipeTester)
  @yeses ["y", "Y", "Yes"]

  # Details
  @docs_url "http://timber.io/docs"
  @manual_installation_url "https://timber.io"
  @support_email "support@timber.io"
  @timber_config_file_name "timber.exs"
  @timber_config_file_path Path.join("config", @timber_config_file_name)
  @repo_url "https://github.com/timberio/timber-elixir"
  @twitter_handle "@timberdotio"
  @website_url "https://timber.io"

  # Messages
  @obtain_key_instructions_message "You can obtain your key by adding an application in https://app.timber.io, or by clicking 'edit' next to your application."
  @stuck_message "Still stuck? Shoot us an email: #{@support_email}"

  def run([]) do
    display_header_message()

    """
    Uh oh! You forgot to include your API key. Please specify it via:

        mix timber.install timber-application-api-key

    #{@obtain_key_instructions_message}

    #{@stuck_message}
    """
    |> warn()
  end

  def run([api_key]) do
    display_header_message()

    case validate_api_key(api_key) do
      :ok ->
        """
        This installer will walk you through setting up Timber in your application.
        At the end we'll send test logs to ensure everything is working properly.
        Grab your axe!
        """
        |> display()

        platform = determine_platform()

        add_config_file(platform)
        link_config_file()
        add_plugs()
        disable_phoenix_logging()
        install_user_context()
        platform_install(platform)
        social_upgrades()
        finish()

        # TODO: display url to open console
        # TODO: display tip to capture user context
        # Usage examples?
        # Social upgrades

      {:error, reason} ->
        """
        Uh oh! It looks like the API key you provided is invalid :(
        Please sure that you copy the key properly.

        #{@obtain_key_instructions_message}

        #{@stuck_message}
        """
        |> warn()
    end
  end

  defp validate_api_key(_), do: :ok

  defp determine_platform do
    """
    #{separator()}
    """
    |> display()

    case ask("Is your app hosted on Heroku?: (y/n)") do
      v when v in @yeses -> :heroku
      v when v in @nos -> :other

      value ->
        warn("#{inspect(value)} is not a valid option. Please try again.\n")
        determine_platform()
    end
  end

  defp add_config_file(platform) do
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

    display_action_starting("Creating #{@timber_config_file_path}...")

    case File.open @timber_config_file_path, [:write] do
      {:ok, file} ->
        case IO.binwrite(file, contents) do
          :ok ->
            display_action_success()

          {:error, reason} ->
            error("Uh oh, we had a problem: #{reason}")
            exit :shutdown
        end

        File.close(file)

      {:error, reason} ->
        error("Uh oh, we had a problem: #{reason}")
        exit :shutdown
    end
  end

  defp link_config_file do
    display_action_starting("Linking #{@timber_config_file_path} in #{@config_file_path}...")
    display_action_success()
  end

  defp add_plugs do
    display_action_starting("Adding Timber plugs to lib/myapp/endpoint.ex...")
    display_action_success()
  end

  defp disable_phoenix_logging do
    display_action_starting("Disabling default Phoenix logging lib/myapp/endpoint.ex...")
    display_action_success()
  end

  defp install_user_context do
    """

    #{separator()}
    """
    |> display()

    case ask("Does your application have user accounts?: (y/n)") do
      v when v in @yeses ->
        """

        Great! Timber can add user context to your logs, allowing you to search
        and tail logs for specific users. To install this, please add this
        code wherever you authenticate your user. Typically in a plug:

            %Timber.Contexts.UserContext{id: id, name: name, email: email}
            |> Timber.add_context()
        """
        |> display()

        case ask("Ready to proceed?: (y/n)") do
          v when v in @yeses -> true
          v when v in @nos -> install_user_context()

          value ->
            warn("#{inspect(value)} is not a valid option. Please try again.\n")
            determine_platform()
        end

      v when v in @nos -> :heroku

      value ->
        warn("#{inspect(value)} is not a valid option. Please try again.\n")
        determine_platform()
    end
  end

  defp platform_install(:heroku) do
    """

    #{separator()}

    Now we need to send your logs to the Timber service.
    Please run this command in a separate terminal and return when complete:

        heroku drains:add url
    """
    |> display()

    wait_for_logs()
  end

  defp platform_install(:other) do
    """

    #{separator()}

    Last step! In a new window commit these changes and deploy your application.
    """
    |> display()

    wait_for_logs()
  end

  defp wait_for_logs(10) do
    display_action_success()
  end

  defp wait_for_logs(iteration \\ 0) do
    :timer.sleep(500)
    rem = rem(iteration, 4)

    IO.ANSI.format(["\r", :clear_line, "Waiting for logs (this can sometimes take a minute)", String.duplicate(".", rem), "\e[u"])
    |> IO.write()

    wait_for_logs(iteration + 1)
  end

  defp social_upgrades do
    """

    #{separator()}

    If you enjoy using Timber, we'd love for you share your experience. And because
    we *love* our customers, we'll add free data to your account 🎉.

    * Get ✨100mb✨ for starring our repo: #{@elixir_repo_url}
    * Get ✨250mb✨ for tweeting your experience to #{@twitter_handle}
    """
    |> display()
  end

  defp finish do
    """

    #{separator()}

    Done! 🎉

    Your Timber console URL: https://app.timber.io
    """
    |> display()

    case ask("How would rate this install experience? 1 (bad) - 5 (perfect)") do
      _ ->
        display("Thanks for your feedback! Let's get to loggin' 🌲")
    end
  end

  defp test_the_pipes do
    display_action_starting("Testing the pipes by sending a few test log messages:")
    display_action_success()
  end

  #
  # Messages
  #

  defp display_action_starting(message) do
    IO.write(message)
    message_length = String.length(message)
    success_length = String.length(acction_success_message())
    difference = 80 - success_length - message_length
    if difference > 0 do
      IO.write(String.duplicate(".", difference))
    end
  end

  defp acction_success_message do
    "✓ Success!"
  end

  defp display_action_success do
    IO.ANSI.format([:green, acction_success_message(), "\n"])
    |> IO.write()
  end

  def display_header_message do
    """
    🌲 Timber installation
    #{separator()}
    Website:       #{@website_url}
    Documentation: #{@docs_url}
    Support:       #{@support_email}
    #{separator()}
    """
    |> display()
  end

  def separator do
    "--------------------------------------------------------------------------------"
  end

  #
  # IO
  #

  defp ask(prompt) do
    input = String.trim(IO.gets("#{prompt}: "))
    if String.length(input) <= 0 do
      warn("Uh oh, we didn't receive an answer :(")
      ask(prompt)
    else
      input
    end
  end

  defp display(message), do: IO.puts(message)

  def warn(message) do
    IO.ANSI.format([:red, "⚠ ", message])
    |> display()
  end

  def error(message) do
    IO.ANSI.format([:red, "⚠ ", message])
    |> display()
  end
end