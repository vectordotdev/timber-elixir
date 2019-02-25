defmodule Mix.Tasks.Timber.TestThePipes do
  @moduledoc """
  Tests and verifies log delivery to the Timber.io service.

  Run this whenever you have problems are want to verify setup. This is typically
  run immediately after installation.

  ## Run

      mix timber.test_the_pipes

  If you installed Timber for production only:

      MIX_ENV=prod mix timber.test_the_pipes

  """

  use Mix.Task

  alias Timber.API
  alias Timber.Config
  alias Timber.LogEntry

  @support_email "support@timber.io"

  @doc """
  Runs the task

  ## Options

  No options are supported at this time.
  """
  @shortdoc "Tests and verifies log delivery to the Timber.io service"
  def run(_args \\ []) do
    {:ok, _} = Application.ensure_all_started(:timber)

    header = ~S"""
     ^  ^    ^  ^  ^   ^      ___I_      ^  ^   ^  ^  ^   ^  ^
     /|\/|\ /|\/|\/|\ /|\    /\-_--\    /|\/|\ /|\/|\/|\ /|\/|\
     /|\/|\ /|\/|\/|\ /|\   /  \_-__\   /|\/|\ /|\/|\/|\ /|\/|\
     /|\/|\ /|\/|\/|\ /|\   |[]| [] |   /|\/|\ /|\/|\/|\ /|\/|\
    ============================================================
                   TIMBER.IO - TESTING THE PIPES
    ============================================================
    """

    IO.puts([IO.ANSI.green(), header])

    with :ok <- verify_api_key_presence(),
         :ok <- verify_delivery!() do
      :ok
    end
  end

  #
  # Verfiication methods
  #

  defp verify_api_key_presence do
    puts("Checking API key presence")

    case Application.get_env(:timber, :api_key) do
      {:system, env_var_name} ->
        case System.get_env(env_var_name) do
          nil ->
            """
            The #{env_var_name} env var is not set!

            This is required because it is specified as the environment variable for the
            Timber API key. Timber cannot deliver messaegs with a valid API key. Try:

                export TIMBER_API_KEY=my-api-key

            Then re-run this command.

            If you continue to have trouble please contact support:

            #{@support_email}
            """
            |> puts(:error)

            :exit

          _api_key ->
            puts("API key found", :success)
            :ok
        end

      nil ->
        """
        Your Timber API key is not set!

        Please make sure you set your API key properly within your `config/config.exs` file:

            # config/config.exs
            config :timber, :api_key, "my-api-key"

        Then re-run this command.

        If you continue to have trouble please contact support:

        #{@support_email}
        """
        |> puts(:error)

        :exit

      _else ->
        puts("API key found", :success)
        :ok
    end
  end

  defp verify_delivery! do
    puts("Verifying log delivery to the Timber API")

    api_key = Config.api_key()
    message = "Testing the pipes (click the inspect icon to view more details)"
    log_entry = LogEntry.new(Timber.Utils.Timestamp.now(), :debug, message)
    log_map = LogEntry.to_map!(log_entry)
    body = Msgpax.pack!([log_map])

    case API.send_logs(api_key, "application/msgpack", body) do
      {:ok, status, _headers, _body} when status in 200..299 ->
        puts("Logs successfully sent! View them at https://app.timber.io", :success)
        :ok

      {:ok, status, _headers, body} ->
        """
        Unable to deliver logs.

        We received a #{status} response from the Timber API:

        #{inspect(body)}

        If you continue to have trouble please contact support:

        #{@support_email}
        """
        |> puts(:error)

        :exit

      {:error, error} ->
        """
        Unable to deliver logs.

        Here's what we received from the Timber API:

        #{inspect(error)}

        If you continue to have trouble please contact support:

        #{@support_email}
        """
        |> puts(:error)

        :exit
    end
  end

  #
  # Util
  #

  defp puts(message, level \\ :info)

  defp puts(message, :info) do
    [IO.ANSI.reset(), "---> #{message}"]
    |> IO.puts()
  end

  defp puts(message, :error) do
    [IO.ANSI.red(), ?\n, String.duplicate("!", 60), ?\n, ?\n, message]
    |> IO.puts()

    :exit
  end

  defp puts(message, :success) do
    [IO.ANSI.green(), "---> ✔ ", message]
    |> IO.puts()
  end
end
