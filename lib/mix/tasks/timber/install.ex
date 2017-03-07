defmodule Mix.Tasks.Timber.Install do
  use Mix.Task

  alias __MODULE__.{Application, ConfigFile, EndpointFile, Feedback, IOHelper, Messages, WebFile}

  require Logger

  def run([]) do
    """
    #{Messages.header()}
    #{Messages.forgot_key()}
    """
    |> IOHelper.puts(:red)
  end

  def run([api_key]) do
    """
    #{Messages.header()}
    #{Messages.intro()}
    """
    |> IOHelper.puts()

    with {:ok, application} <- Application.new(api_key),
         :ok <- create_config_file(application),
         :ok <- link_config_file(application),
         :ok <- add_plugs(application),
         :ok <- disable_default_phoenix_logging(application),
         :ok <- install_user_context(),
         :ok <- install_on_platform(application),
         :ok <- finish(),
         :ok <- Feedback.collect()
    do
      true
    else
      {:error, reason} ->
        """
        Bummer! We encountered a problem:

        #{reason}

        Please try again.

        #{Messages.get_help()}
        """
        |> IOHelper.puts(:red)
    end
  end

  defp create_config_file(application) do
    Messages.action_starting("Creating #{@timber_config_file_path}...")
    |> IOHelper.write()

    case ConfigFile.create(application) do
      :ok ->
        Message.success()
        |> IOHelper.puts(:green)

        :ok

      {:error, reason} -> {:error, reason}
    end
  end

  # Links config/timber.exs within config/config.exs
  defp link_config_file(%{config_file_path: config_file_path}) do
    Messages.action_starting("Linking #{@timber_config_file_path} in #{config_file_path}...")
    |> IOHelper.write()

    case ConfigFile.link(config_file_path) do
      :ok ->
        Message.success()
        |> IOHelper.puts(:green)

      {:error, reason} -> {:error, reason}
    end
  end

  defp add_plugs(%{endpoint_file_path: endpoint_file_path}) do
    Messages.starting_message("Adding Timber plugs to #{endpoint_file_path}...")
    |> IOHelper.write()

    case EndpointFile.link(endpoint_file_path) do
      :ok ->
        Messages.success()
        |> IOHelper.puts(:green)

      {:error, reason} -> {:error, reason}
    end
  end

  defp disable_default_phoenix_logging(%{web_file_path: web_file_path}) do
    Messages.action_starting("Disabling default Phoenix logging #{web_file_path}...")
    |> IOHelper.write()

    case WebFile.update(web_file_path) do
      :ok ->
        Messages.success()
        |> IOHelper.puts(:green)

      {:error, reason} -> {:error, reason}
    end
  end

  defp install_user_context do
    """

    #{Messags.separator()}
    """
    |> IOHelper.puts()

    case IOHelper.ask_yes_no("Does your application have user accounts? (y/n)") do
      :yes ->
        Messages.user_context_instructions()
        |> IOHelper.puts()

        case IOHelper.ask_yes_no("Ready to proceed? (y/n)") do
          :yes -> :ok
          :no -> install_user_context()
        end

      :no -> false
    end
  end

  defp install_on_platform(%{platform_type: "heroku"} = application) do
    Messages.heroku_drain_instructions(application)
    |> IOHelper.puts()

    wait_for_logs()
  end

  defp install_on_platform(_application) do
    Messages.action_starting_message("Sending a few test logs...")
    |> IOHelper.write()

    Logger.info("testing")

    Messages.success()
    |> IOHelper.puts(:green)

    wait_for_logs()
  end

  defp wait_for_logs(10) do
    Messages.success()
    |> IOHelper.puts(:green)
    :ok
  end

  defp wait_for_logs(iteration \\ 0) do
    :timer.sleep(500)
    rem = rem(iteration, 4)

    IO.ANSI.format(["\r", :clear_line, "Waiting for logs (this can sometimes take a minute)", String.duplicate(".", rem), "\e[u"])
    |> IOHelper.write()

    wait_for_logs(iteration + 1)
  end

  defp finish do
    Messages.finish()
    |> IOHelper.puts()
  end
end