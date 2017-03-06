defmodule Mix.Tasks.Timber.Install do
  use Mix.Task

  alias __MODULE__.HTTPClient

  @nos ["n", "N", "No"]
  @yeses ["y", "Y", "Yes"]

  # Details
  @api_url "https://api.timber.io"
  @docs_url "http://timber.io/docs"
  @support_email "support@timber.io"
  @timber_config_file_name "timber.exs"
  @timber_config_file_path Path.join(["config", @timber_config_file_name])
  @repo_url "https://github.com/timberio/timber-elixir"
  @twitter_handle "@timberdotio"
  @website_url "https://timber.io"

  # Clients
  @file_client Keyword.get(Application.get_env(:timber, __MODULE__, []), :file_client, File)
  @http_client Keyword.get(Application.get_env(:timber, __MODULE__, []), :http_client, HTTPClient)
  @io_client Keyword.get(Application.get_env(:timber, __MODULE__, []), :io_client, IO)
  @path_client Keyword.get(Application.get_env(:timber, __MODULE__, []), :path_client, Path)

  def run([]) do
    """
    #{header_message()}

    Uh oh! You forgot to include your API key. Please specify it via:

        mix timber.install timber-application-api-key

    #{obtain_key_instructions_message()}

    #{get_help_message()}
    """
    |> puts(:red)
  end

  def run([api_key]) do
    """
    #{header_message()}

    This installer will walk you through setting up Timber in your application.
    At the end we'll make sure logs are flowing properly.
    Grab your axe!
    """
    |> puts()

    with {:ok, application} <- get_application(api_key),
         :ok <- add_config_file(application),
         :ok <- link_config_file(),
         :ok <- add_plugs(),
         :ok <- disable_default_phoenix_logging(),
         :ok <- install_user_context(),
         :ok <- install_on_platform(application),
         :ok <- finish(),
         :ok <- collect_feedback()
    do
      true
    else
      {:error, reason} ->
        """
        Bummer! We encountered a problem:

        #{reason}

        Please try again.

        #{get_help_message()}
        """
        |> puts(:red)
    end
  end

  defp get_application(_api_key) do
    case @http_client.request("GET", "/installer/application") do
      {:ok, 200, %{"name" => name, "subdomain" => subdomain, "platform_type" => platform_type}} ->
        application = %{
          name: name,
          subdomain: subdomain,
          platform_type: platform_type
        }
        {:ok, application}

      {:ok, 403, _} ->
        reason =
          """
          Uh oh! It looks like the API key you provided is invalid :(
          Please ensure that you copied the key properly.

          #{obtain_key_instructions_message()}

          #{get_help_message()}
          """
        {:error, reason}

      {:error, reason} -> {:error, reason}
    end
  end

  # Adds the config/timber.exs file to be linked in config/config.exs
  defp add_config_file(_application) do
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

    action_starting_message("Creating #{@timber_config_file_path}...")
    |> write()

    case write_file(@timber_config_file_path, contents) do
      :ok ->
        success_message()
        |> puts(:green)

        :ok

      {:error, reason} ->
        {:error, "Uh oh, we had a problem writing to #{@timber_config_file_path}: #{reason}"}
    end
  end

  # Links config/timber.exs within config/config.exs
  defp link_config_file do
    config_file_path =
      Path.join(["config", "config.exs"])
      |> find_file()

    action_starting_message("Linking #{@timber_config_file_path} in #{config_file_path}...")
    |> write()

    contents =
      """
      # Import Timber, structured logging
      import_config \"#{@timber_config_file_name}\"
      """

    case append_to_file_once(config_file_path, contents) do
      :ok ->
        success_message()
        |> puts(:green)

      {:error, reason} ->
        {:error, "Uh oh, we had a problem writing to #{config_file_path}: #{reason}"}
    end
  end

  defp add_plugs do
    endpoint_file_path =
      Path.join(["lib", "*", "endpoint.ex"])
      |> find_file()

    action_starting_message("Adding Timber plugs to #{endpoint_file_path}...")
    |> write()

    pattern = ~r/( *)plug ElixirPhoenixExampleApp\.Router/
    replacement =
      "\\1# Add Timber plugs for capturing HTTP context and events\n" <>
        "\\1plug Timber.Integrations.ContextPlug\n" <>
        "\\1plug Timber.Integrations.EventPlug\n\n\\0"

    case replace_in_file_once(endpoint_file_path, pattern, replacement) do
      :ok ->
        success_message()
        |> puts(:green)

      {:error, reason} ->
        {:error, "Uh oh, we had a problem writing to #{endpoint_file_path}: #{reason}"}
    end
  end

  defp disable_default_phoenix_logging do
    web_file_path =
      Path.join(["web", "web.ex"])
      |> find_file()

    action_starting_message("Disabling default Phoenix logging #{web_file_path}...")
    |> write()

    pattern = ~r/use Phoenix\.Controller/
    replacement = "\\0, log: false"

    case replace_in_file_once(web_file_path, pattern, replacement) do
      :ok ->
        success_message()
        |> puts(:green)

      {:error, reason} ->
        {:error, "Uh oh, we had a problem writing to #{web_file_path}: #{reason}"}
    end
  end

  defp install_user_context do
    """

    #{separator()}
    """
    |> puts()

    case ask("Does your application have user accounts? (y/n)") do
      v when v in @yeses ->
        """

        Great! Timber can add user context to your logs, allowing you to search
        and tail logs for specific users. To install this, please add this
        code wherever you authenticate your user. Typically in a plug:

            %Timber.Contexts.UserContext{id: id, name: name, email: email}
            |> Timber.add_context()
        """
        |> puts()

        case ask("Ready to proceed? (y/n)") do
          v when v in @yeses -> :ok
          v when v in @nos -> install_user_context()

          v ->
            puts("#{inspect(v)} is not a valid option. Please try again.\n", :red)
            install_user_context()
        end

      v when v in @nos -> :heroku

      v ->
        puts("#{inspect(v)} is not a valid option. Please try again.\n", :red)
        install_user_context()
    end
  end

  defp install_on_platform(%{platform_type: "heroku"}) do
    """

    #{separator()}

    Now we need to send your logs to the Timber service.
    Please run this command in a separate terminal and return back here when complete:

        heroku drains:add url
    """
    |> puts()

    wait_for_logs()
  end

  defp install_on_platform(_application) do
    action_starting_message("Sending a few test logs...")
    |> write()

    test_http_client()

    success_message()
    |> puts(:green)

    wait_for_logs()
  end

  defp wait_for_logs(10) do
    display_action_success()
    :ok
  end

  defp wait_for_logs(iteration \\ 0) do
    :timer.sleep(500)
    rem = rem(iteration, 4)

    IO.ANSI.format(["\r", :clear_line, "Waiting for logs (this can sometimes take a minute)", String.duplicate(".", rem), "\e[u"])
    |> write()

    wait_for_logs(iteration + 1)
  end

  defp finish do
    """

    #{separator()}

    Done! Commit these changes and deploy. 🎉

    * Your Timber console URL: https://app.timber.io
    * Get ✨100mb✨ for starring our repo: #{@repo_url}
    * Get ✨50mb✨ for following #{@twitter_handle} on twitter
    * Get ✨250mb✨ for tweeting your experience to #{@twitter_handle}

    (your account will be credited within 2-3 business days)
    """
    |> puts()
  end

  defp collect_feedback do
    case ask("How would rate this install experience? 1 (bad) - 5 (perfect)") do
      v when v in ["4", "5"] ->
        display("💖 We love you too! Let's get to loggin' 🌲")

      v when v in ["1", "2", "3"] ->
        display("Bummer! That is certainly not the experience we were going for.")

        case ask("May we email you to resolve the issue you're having? (y/n)") do
          v when v in @yeses ->
            display("Great! We'll be in touch.")

          v when v in @nos ->
            display("Thank you trying Timber anyway. We wish we would have left a better impression.")
        end

      v ->
        puts("#{inspect(v)} is not a valid option. Please try again.\n", :red)
        finish()
    end

    :ok
  end

  #
  # Files
  #

  defp append_to_file_once(path, contents) do
    case @file_client.read(path) do
      {:ok, current_contents} ->
        trimmed_contents = String.trim(contents)

        if String.contains?(current_contents, trimmed_contents) do
          :ok
        else
          case @file_client.open(path, [:append]) do
            {:ok, file} ->
              result = @io_client.binwrite(file, contents)
              @file_client.close(file)
              result

            {:error, reason} -> {:error, reason}
          end
        end

      {:error, reason} -> {:error, reason}
    end
  end

  defp replace_in_file_once(path, pattern, replacement) do
    case @file_client.read(path) do
      {:ok, contents} ->
        if String.contains?(contents, replacement) do
          :ok

        else
          new_contents = String.replace(contents, pattern, replacement)
          write_file(path, new_contents)
        end

      {:error, reason} -> {:error, reason}
    end
  end

  defp write_file(path, contents) do
    case @file_client.open(path, [:write]) do
      {:ok, file} ->
        result = @io_client.binwrite(file, contents)
        @file_client.close(file)
        result

      {:error, reason} -> {:error, reason}
    end
  end

  # Ensures that the specified file exists. If it does not, it prompts
  # the user to enter the file path.
  defp find_file(path) do
    case @path_client.wildcard(path) do
      [path] -> path

      [] ->
        case ask("We couldn't locate a #{path} file. Please enter the correct path") do
          v -> find_file(v)
        end

      _multiple ->
        case ask("We found multiple files matching #{path}. Please enter the correct path") do
          v -> find_file(v)
        end
    end
  end

  #
  # Messages
  #

  defp action_starting_message(message) do
    message_length = String.length(message)
    success_length = String.length(success_message())
    difference = 80 - success_length - message_length
    if difference > 0 do
      message <> String.duplicate(".", difference)
    else
      message
    end
  end

  defp success_message do
    "✓ Success!"
  end

  def header_message do
    """
    🌲 Timber installation
    #{separator()}
    Website:       #{@website_url}
    Documentation: #{@docs_url}
    Support:       #{@support_email}
    #{separator()}
    """
    |> puts()
  end

  def obtain_key_instructions_message do
    "You can obtain your key by adding an application in https://app.timber.io, or by clicking 'edit' next to your application."
  end

  def separator do
    "--------------------------------------------------------------------------------"
  end

  def get_help_message do
    "Still stuck? Shoot us an email: #{@support_email}"
  end

  #
  # IO
  #

  defp ask(prompt) do
    case @io_client.gets("#{prompt}: ") do
      value when is_binary(value) ->
        input = String.trim(value)

        if String.length(input) <= 0 do
          puts("Uh oh, we didn't receive an answer :(", :red)
          ask(prompt)
        else
          input
        end

      :eof -> raise("Error getting user input: end of file reached")

      {:error, reason} -> raise("Error gettin guser input: #{inspect(reason)}")
    end
  end

  defp puts(message), do: @io_client.puts(message)

  defp puts(message, color) do
    IO.ANSI.format([color, message])
    |> @io_client.puts()
  end

  def write(message) do
    @io_client.write(message)
  end

  def write(message, color) do
    IO.ANSI.format([color, message])
    |> @io_client.write()
  end

  #
  # HTTP request
  #

  defmodule HTTPClient do
    # This is rather crude way of making HTTP requests, but it beats requiring an HTTP client
    # as a dependency just for this installer.
    def request("GET", url, _headers, _body) do
      {response, _} = System.cmd("curl", ["-s", "-w _STATUS_:%{http_code}", "test"])

      case String.split(response, " _STATUS_:", parts: 2) do
        [body, status_str] ->
          case Integer.parse(status_str) do
            {status, _units} ->
              case Poison.decode(body) do
                {:ok, %{"data" => data}} -> {:ok, status, data}

                {:error, reason} ->
                  message =
                    """
                    We're having trouble communicating with the Timber API.
                    The response sent back was malformed :(
                    """
                  {:error, message}

                {:error, reason, _position} ->
                  message =
                    """
                    We're having trouble communicating with the Timber API.
                    The response sent back was malformed :(
                    """
                  {:error, message}
              end
          end

        _ ->
          message =
            """
            We're having trouble connecting to #{@api_url}. Please ensure that
            this computer can connect to this URL. This is neccessary to verify
            your API key and test installation.
            """
          {:error, message}
      end
    end
  end
end