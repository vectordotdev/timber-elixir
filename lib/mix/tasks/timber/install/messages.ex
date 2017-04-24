defmodule Mix.Tasks.Timber.Install.Messages do
  @moduledoc false

  alias Mix.Tasks.Timber.Install.IOHelper

  @app_url "https://app.timber.io"
  @docs_url "https://timber.io/docs"
  @repo_url "https://github.com/timberio/timber-elixir"
  @support_email "support@timber.io"
  @twitter_handle "@timberdotio"
  @website_url "https://timber.io"

  def action_starting(message) do
    message_length = String.length(message)
    success_length = String.length(success())
    difference = 80 - success_length - message_length
    if difference > 0 do
      message <> String.duplicate(".", difference)
    else
      message
    end
  end

  def commit_and_deploy_reminder do
    """
    Last step!

        #{IOHelper.colorize("git add config/timber.exs", :blue)}
        #{IOHelper.colorize("git commit -am 'Install timber'", :blue)}

    Push and deploy. 🚀
    """
  end

  def free_data() do
    upgrades =
      """
      * Get ✨ 250mb✨ for tweeting your experience to #{@twitter_handle}
      * Get ✨ 100mb✨ for starring our repo: #{@repo_url}
      * Get ✨ 50mb✨ for following #{@twitter_handle} on twitter
      """
      |> IOHelper.colorize(:yellow)

      """

    #{separator()}

    #{upgrades}
    (Your account will be credited within 2-3 business days.
     If you do not notice a credit please contact us: #{@support_email})
    """
  end

  def forgot_key do
    """
    Hey there! Welcome to Timber. In order to proceed, you'll need an API key.
    If you already have one, you can run this installer like:

        #{IOHelper.colorize("mix timber.install timber-application-api-key", :blue)}

    #{obtain_key_instructions()}

    #{get_help()}
    """
  end

  def get_help do
    """
    Still stuck?

    * Shoot us an email: #{@support_email}
    * Or, file an issue: #{@repo_url}/issues
    """
  end

  def header do
    header =
      """

      🌲 Timber.io Elixir Installer

       ^  ^  ^   ^      ___I_      ^  ^   ^  ^  ^   ^  ^
      /|\\/|\\/|\\ /|\\    /\\-_--\\    /|\\/|\\ /|\\/|\\/|\\ /|\\/|\\
      /|\\/|\\/|\\ /|\\   /  \\_-__\\   /|\\/|\\ /|\\/|\\/|\\ /|\\/|\\
      /|\\/|\\/|\\ /|\\   |[]| [] |   /|\\/|\\ /|\\/|\\/|\\ /|\\/|\\
      """
      |> IOHelper.colorize(:green)

      """
    #{header}
    #{separator()}
    Website:       #{@website_url}
    Documentation: #{@docs_url}
    Support:       #{@support_email}
    #{separator()}
    """
  end

  def heroku_drain_instructions(heroku_drain_url) do
    """
    #{separator()}

    Now we need to send your logs to the Timber service.
    Please run this command in a separate terminal and return back here when complete:

        #{IOHelper.colorize("heroku drains:add #{heroku_drain_url}", :blue)}
    """
  end

  def intro do
    """
    This installer will walk you through setting up Timber in your application.
    At the end we'll make sure logs are flowing properly. Please note, this
    installer is idempotent, you can run it as many times as you need.

    Grab your axe!
    """
  end

  def obtain_key_instructions do
    """
    Don't have a key? Head over to:

        #{IOHelper.colorize(@app_url, :blue)}

    Once there, create an application. Your API key will be displayed afterwards.
    For more detailed instructions, checkout our docs page:

    https://timber.io/docs/app/obtain-api-key/
    """
  end

  def outgoing_http_instructions do
    """

    Great! Timber can track all of your outgoing HTTP requests and
    responses. You'll have access to the body contents, headers,
    and all other request details. Offering all of the data you need
    to solve an issue when it arises.

    To install, please add this code wherever you issue HTTP requests:

        Timber.Events.HTTPClient.log(method, headers, url, :stripe, fn ->
          :hackney.request(method, path) # just an example, use any HTTP client you want
        end)

        time_ms = Timber.duration_ms(timer)
        {event, message} =
          HTTPClientResponseEvent.new_with_message(headers: headers, status: status, time_ms: time_ms)
        level = response_logger_level(status, time_ms)
        Logger.log(level, message, event: event)

        %Timber.Events.HTTPClientRequest{id: id, name: name, email: email}
    """
  end

  def separator do
    "--------------------------------------------------------------------------------"
  end

  def spinner(0), do: "-"

  def spinner(1), do: "\\"

  def spinner(2), do: "/"

  def success, do: "✓ Success!"

  def user_context_instructions do
    code =
      """
          %Timber.Contexts.UserContext{id: id, name: name, email: email}
          |> Timber.add_context()
      """
      |> IOHelper.colorize(:blue)

    """

    Great! Timber can add user context to your logs, allowing you to search
    and tail logs for specific users. To install this, please follow the
    appropraite instructions below:

    1. If you're using Gaurdian (an elixir authentication library), checkout
       this gist: https://gist.github.com/binarylogic/50901f453587748c3d70295e49f5797a

    2. For everything else, simply add the following code immediately after
       you load (or build) your user:

    #{code}
    """
  end

  def waiting_for_logs do
    "Waiting for logs (This can sometimes take a minute)"
  end
end
