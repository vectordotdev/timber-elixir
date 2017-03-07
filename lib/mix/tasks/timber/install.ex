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

    application = Application.new!(api_key)
    create_config_file!(application)
    link_config_file!(application)
    add_plugs!(application)
    disable_default_phoenix_logging!(application)
    install_user_context!()
    install_on_platform!(application)
    finish!()
    Feedback.collect()

  rescue
    e ->
      message = Exception.message(e)
      stacktrace = Exception.format_stacktrace(System.stacktrace())

      """


      #{String.duplicate("!", 80)}

      #{message}
      #{Messages.get_help()}

      ---

      Here's the stacktrace for reference:

      #{stacktrace}
      """
      |> IOHelper.puts(:red)
  end

  defp create_config_file!(application) do
    Messages.action_starting("Creating #{ConfigFile.file_path()}...")
    |> IOHelper.write()

    case ConfigFile.create!(application) do
      :ok ->
        Messages.success()
        |> IOHelper.puts(:green)

        :ok

      {:error, reason} -> {:error, reason}
    end
  end

  # Links config/timber.exs within config/config.exs
  defp link_config_file!(%{config_file_path: config_file_path}) do
    Messages.action_starting("Linking #{ConfigFile.file_path()} in #{config_file_path}...")
    |> IOHelper.write()

    ConfigFile.link!(config_file_path)

    Messages.success()
    |> IOHelper.puts(:green)
  end

  defp add_plugs!(%{endpoint_file_path: endpoint_file_path, module_name: module_name}) do
    Messages.action_starting("Adding Timber plugs to #{endpoint_file_path}...")
    |> IOHelper.write()

    EndpointFile.update!(endpoint_file_path, module_name)

    Messages.success()
    |> IOHelper.puts(:green)
  end

  defp disable_default_phoenix_logging!(%{web_file_path: web_file_path}) do
    Messages.action_starting("Disabling default Phoenix logging #{web_file_path}...")
    |> IOHelper.write()

    WebFile.update!(web_file_path)

    Messages.success()
    |> IOHelper.puts(:green)
  end

  defp install_user_context! do
    """

    #{Messages.separator()}
    """
    |> IOHelper.puts()

    case IOHelper.ask_yes_no("Does your application have user accounts? (y/n)") do
      :yes ->
        Messages.user_context_instructions()
        |> IOHelper.puts()

        case IOHelper.ask_yes_no("Ready to proceed? (y/n)") do
          :yes -> :ok
          :no -> install_user_context!()
        end

      :no -> false
    end
  end

  defp install_on_platform!(%{platform_type: "heroku", heroku_drain_url: heroku_drain_url} = application) do
    Messages.heroku_drain_instructions(heroku_drain_url)
    |> IOHelper.puts()

    Application.wait_for_logs(application)
  end

  defp install_on_platform!(application) do
    Messages.action_starting("Sending a few test logs...")
    |> IOHelper.write()

    Logger.info("testing")

    Messages.success()
    |> IOHelper.puts(:green)

    Application.wait_for_logs(application)
  end

  defp finish! do
    Messages.finish()
    |> IOHelper.puts()
  end
end