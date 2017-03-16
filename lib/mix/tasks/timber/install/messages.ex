defmodule Mix.Tasks.Timber.Install.Messages do
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

  def finish() do
    """

    #{separator()}

    Done! Commit these changes and deploy. 🚀

    * Timber URL: https://app.timber.io
    * Get ✨ 250mb✨ for tweeting your experience to #{@twitter_handle}
    * Get ✨ 100mb✨ for starring our repo: #{@repo_url}
    * Get ✨ 50mb✨ for following #{@twitter_handle} on twitter

    (Your account will be credited within 2-3 business days.
     If you do not notice a credit please contact us: #{@support_email})
    """
  end

  def forgot_key do
    """
    Uh oh! You forgot to include your API key. Please specify it via:

        mix timber.install timber-application-api-key

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
    """

    🌲 Timber.io Elixir Installer

     ^  ^  ^   ^      ___I_      ^  ^   ^  ^  ^   ^  ^
    /|\\/|\\/|\\ /|\\    /\\-_--\\    /|\\/|\\ /|\\/|\\/|\\ /|\\/|\\
    /|\\/|\\/|\\ /|\\   /  \\_-__\\   /|\\/|\\ /|\\/|\\/|\\ /|\\/|\\
    /|\\/|\\/|\\ /|\\   |[]| [] |   /|\\/|\\ /|\\/|\\/|\\ /|\\/|\\
    """
  end

  def contact_and_support do
    """
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

        heroku drains:add #{heroku_drain_url}
    """
  end

  def http_client_setup do
    """
    In order to proceed, an HTTP client must be specified:

    1. In mix.exs, add :hackney to your dependencies:

        def deps do
          [{:hackney, "~> 1.6"}]
        end

    2. In mix.exs, add :hackney to your :applications list:

        def application do
          [applications: [:hackney]]
        end

    3. Run mix deps.get

    4. Quit and re-run this installer. It is perfectly safe to do so.
       This installer is idempotent.

    * Note: advanced users can define their own HTTP client if desired.
      Please see Timber.Transports.HTTP.Client for more details.
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

        #{@app_url}

    Once there, create an application. Your API key will be displayed afterwards.
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

  def success do
    "✓ Success!"
  end

  def user_context_instructions do
    """

    Great! Timber can add user context to your logs, allowing you to search
    and tail logs for specific users. To install this, please add this
    code wherever you authenticate your user. Typically in a plug:

        %Timber.Contexts.UserContext{id: id, name: name, email: email}
        |> Timber.add_context()
    """
  end
end