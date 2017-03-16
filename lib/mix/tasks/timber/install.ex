defmodule Mix.Tasks.Timber.Install do
  use Mix.Task

  alias __MODULE__.{Application, ConfigFile, EndpointFile, Event, Feedback, HTTPClient,
    IOHelper, Messages, Platform, WebFile}
  alias Mix.Tasks.Timber.Install.HTTPClient.InvalidAPIKeyError

  require Logger

  def run([]) do
    Messages.header()
    |> IOHelper.puts(:green)

    Messages.contact_and_support()
    |> IOHelper.puts()

    Messages.forgot_key()
    |> IOHelper.puts(:red)
  end

  def run([api_key]) do
    session_id = generate_session_id()

    try do
      :ok = HTTPClient.start()

      Event.send!(:started, session_id, api_key)

      Messages.header()
      |> IOHelper.puts(:green)

      Messages.contact_and_support()
      |> IOHelper.puts()

      application = Application.new!(session_id, api_key)
      create_config_file!(application)
      link_config_file!(application)
      add_plugs!(application)
      disable_default_phoenix_logging!(application)
      install_user_context!(session_id, api_key)
      #install_http_client_context!(session_id, api_key)
      Platform.install!(session_id, application)
      finish!(session_id, api_key)
      Feedback.collect(session_id, api_key)

    rescue
      e in InvalidAPIKeyError ->
        message = Exception.message(e)

        """
        #{String.duplicate("!", 80)}

        #{message}
        #{Messages.get_help()}
        """
        |> IOHelper.puts(:red)

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

        case IOHelper.ask_yes_no("Permission to send this error to Timber?") do
          :yes ->
            data = %{message: message, stacktrace: stacktrace}
            Event.send!(:exception, session_id, api_key, data: data)

          :no -> :ok
        end

        :ok
    end
  end

  def generate_session_id() do
    32
    |> :crypto.strong_rand_bytes()
    |> Base.encode16(case: :lower)
    |> binary_part(0, 32)
  end

  defp create_config_file!(application) do
    ConfigFile.create!(application)

    Messages.action_starting("Creating #{ConfigFile.file_path()}...")
    |> IOHelper.write()

    Messages.success()
    |> IOHelper.puts(:green)
  end

  # Links config/timber.exs within config/config.exs
  defp link_config_file!(%{config_file_path: config_file_path}) do
    Messages.action_starting("Linking #{ConfigFile.file_path()} in #{config_file_path}...")
    |> IOHelper.write()

    ConfigFile.link!(config_file_path)

    Messages.success()
    |> IOHelper.puts(:green)
  end

  defp add_plugs!(%{endpoint_file_path: endpoint_file_path}) do
    Messages.action_starting("Adding Timber plugs to #{endpoint_file_path}...")
    |> IOHelper.write()

    EndpointFile.update!(endpoint_file_path)

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

  defp install_user_context!(session_id, api_key) do
    """

    #{Messages.separator()}
    """
    |> IOHelper.puts()

    answer = IOHelper.ask_yes_no("Does your application have user accounts?")
    Event.send!(:user_context_answer, session_id, api_key, data: %{answer: answer})

    case answer do
      :yes ->
        Messages.user_context_instructions()
        |> IOHelper.puts()

        case IOHelper.ask_yes_no("Ready to proceed?") do
          :yes -> :ok
          :no -> install_user_context!(session_id, api_key)
        end

      :no ->
        false
    end
  end

  # defp install_http_client_context!(session_id, api_key) do
  #   """

  #   #{Messages.separator()}
  #   """
  #   |> IOHelper.puts()

  #    answer = IOHelper.ask_yes_no("Does your application send outgoing HTTP requests?")
  #    Event.send!(:http_tracking_answer, session_id, api_key, data: %{answer: answer})

  #   case answer do
  #     :yes ->
  #       Messages.outgoing_http_instructions()
  #       |> IOHelper.puts()

  #       case IOHelper.ask_yes_no("Ready to proceed?") do
  #         :yes -> :ok
  #         :no -> install_http_client_context!()
  #       end

  #     :no -> false
  #   end
  # end


  defp finish!(session_id, api_key) do
    Event.send!(:success, session_id, api_key)

    Messages.finish()
    |> IOHelper.puts()
  end
end