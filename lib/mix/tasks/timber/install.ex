defmodule Mix.Tasks.Timber.Install do
  @moduledoc false

  use Mix.Task

  alias __MODULE__.{API, Application, ConfigFile, EndpointFile, IOHelper, Messages,
    WebFile}
  alias Mix.Tasks.Timber.Install.HTTPClient.InvalidAPIKeyError
  alias Mix.Tasks.Timber.TestThePipes

  require Logger

  def run([]) do
    Messages.header()
    |> IOHelper.puts(:green)

    Messages.contact_and_support()
    |> IOHelper.puts()

    Messages.forgot_key()
    |> IOHelper.puts()
  end

  def run([api_key]) do
    api = API.new(api_key)

    try do
      :ok = API.start()

      API.event!(api, :started)

      Messages.header()
      |> IOHelper.puts(:green)

      Messages.contact_and_support()
      |> IOHelper.puts()

      application = Application.new!(api)

      create_config_file!(application)
      link_config_file!(application)
      add_plugs!(Code.ensure_loaded?(Phoenix), application)
      disable_default_phoenix_logging!(application)
      install_user_context!(api)
      #install_http_client_context!(session_id, api_key)
      platform_install!(api, application)

      API.event!(api, :success)

      Messages.free_data()
      |> IOHelper.puts()

      """

      #{Messages.separator()}
      """
      |> IOHelper.puts()

      Messages.commit_and_deploy_reminder()
      |> IOHelper.puts()

      """
      #{Messages.separator()}
      """
      |> IOHelper.puts()

      collect_feedback(api)

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

        # case IOHelper.ask_yes_no("Permission to send this error to Timber?") do
        #   :yes ->
        #     data = %{message: message, stacktrace: stacktrace}
        #     API.event!(api, :exception, data: data)

        #   :no -> :ok
        # end

        :ok
    end
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

  defp add_plugs!(false, _), do: nil

  defp add_plugs!(true, %{endpoint_file_path: endpoint_file_path} = api) do
    file_explanation = "We need this so that we can install the Timber plugs."
    endpoint_file_path = PathHelper.find(["lib", "**", "endpoint.ex"], not_found_explanation, api)

    if endpoint_file_path do
      endpoint_module_name =
        if endpoint_file_path,
          do: "#{module_name}.Endpoint",
          else: nil


      Messages.action_starting("Adding Timber plugs to #{endpoint_file_path}...")
      |> IOHelper.write()

      EndpointFile.update!()

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

  defp install_user_context!(api) do
    """

    #{Messages.separator()}
    """
    |> IOHelper.puts()

    answer = IOHelper.ask_yes_no("Does your application have user accounts?")
    API.event!(api, :user_context_answer, %{answer: Atom.to_string(answer)})

    case answer do
      :yes ->
        Messages.user_context_instructions()
        |> IOHelper.puts()

        case IOHelper.ask_yes_no("Ready to proceed?") do
          :yes -> :ok
          :no -> install_user_context!(api)
        end

      :no ->
        false
    end
  end

  # defp install_http_client_context!(api) do
  #   """

  #   #{Messages.separator()}
  #   """
  #   |> IOHelper.puts()

  #    answer = IOHelper.ask_yes_no("Does your application send outgoing HTTP requests?")
  #    API.event!(api, :http_tracking_answer, data: %{answer: answer})

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

  defp platform_install!(api, %{platform_type: "heroku", heroku_drain_url: heroku_drain_url}) do
    Messages.heroku_drain_instructions(heroku_drain_url)
    |> IOHelper.puts()

    API.wait_for_logs(api)
  end

  defp platform_install!(%{api_key: api_key} = api, _application) do
    :ok = check_for_http_client(api)

    Messages.action_starting("Sending a few test logs...")
    |> IOHelper.write()

    # We manually initialize the backend here and mimic the behavior
    # of the GenEvent system

    {:ok, http_client} = Timber.LoggerBackends.HTTP.init(Timber.LoggerBackends.HTTP, [api_key: api_key])

    log_entries = TestThePipes.log_entries()

    http_client =
      Enum.reduce(log_entries, http_client, fn log_entry, http_client ->
        {:ok, http_client} = Timber.LoggerBackends.HTTP.handle_event(log_entry, http_client)
        http_client
      end)

    Timber.LoggerBackends.HTTP.handle_event(:flush, http_client)

    Messages.success()
    |> IOHelper.puts(:green)

    API.wait_for_logs(api)
  end

  defp check_for_http_client(api) do
    if Code.ensure_loaded?(:hackney) do
      API.event!(api, :http_client_found)

      case :hackney.start() do
        :ok -> :ok
        {:error, {:already_started, _name}} -> :ok
        other -> other
      end

      :ok
    else
      API.event!(api, :http_client_not_found)

      Messages.http_client_setup()
      |> IOHelper.puts(:red)

      exit :shutdown
    end
  end

  defp collect_feedback(api) do
    case IOHelper.ask("How would rate this install experience? 1 (bad) - 5 (perfect)") do
      v when v in ["4", "5"] ->
        API.event!(api, :feedback, %{rating: v})

        """

        💖  We love you too! Let's get to loggin' 🌲
        """
        |> IOHelper.puts()

      v when v in ["1", "2", "3"] ->
        """

        Bummer! That is certainly not the experience we were going for.

        Could you tell us why you a bad experience?

        (this will be sent directly to the Timber engineering team)
        """
        |> IOHelper.puts()

        case IOHelper.ask("Type your comments (enter sends)") do
          comments ->
            API.event!(api, :feedback, %{rating: v, comments: comments})

            """

            Thank you! We take feedback seriously and will work to resolve this.
            """
            |> IOHelper.puts()
        end

      v ->
        IOHelper.puts("#{inspect(v)} is not a valid option. Please enter a number between 1 and 5.\n", :red)
        collect_feedback(api)
    end
  end
end
