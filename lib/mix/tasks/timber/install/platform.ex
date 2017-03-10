defmodule Mix.Tasks.Timber.Install.Platform do
  alias Mix.Tasks.Timber.Install.{Application, Event, IOHelper, Messages}
  alias Mix.Tasks.Timber.TestThePipes

  def install!(session_id, %{platform_type: "heroku", heroku_drain_url: heroku_drain_url} = application) do
    Messages.heroku_drain_instructions(heroku_drain_url)
    |> IOHelper.puts()

    Application.wait_for_logs(application, session_id)
  end

  def install!(session_id, %{api_key: api_key} = application) do
    :ok = check_for_http_client(session_id, api_key)

    Messages.action_starting("Sending a few test logs...")
    |> IOHelper.write()

    {:ok, http_client} = Timber.Transports.HTTP.init()
    {:ok, http_client} = Timber.Transports.HTTP.configure([api_key: api_key], http_client)

    log_entries = TestThePipes.log_entries()

    http_client =
      Enum.reduce(log_entries, http_client, fn log_entry, http_client ->
        {:ok, http_client} = Timber.Transports.HTTP.write(log_entry, http_client)
        http_client
      end)

    Timber.Transports.HTTP.flush(http_client)

    Messages.success()
    |> IOHelper.puts(:green)

    Application.wait_for_logs(application, session_id)
  end

  defp check_for_http_client(session_id, api_key) do
    if Code.ensure_loaded?(:hackney) do
      case :hackney.start() do
        :ok -> :ok
        {:error, {:already_started, _name}} -> :ok
        other -> other
      end

      :ok
    else
      Event.send!(:http_client_not_found, session_id, api_key)

      """
      In order to proceed, an HTTP client must be specified:

      1. Add :hackney to your dependencies:

          def deps do
            [{:hackney, "~> 1.6"}]
          end

      2. Add :hackney to your :applications list:

          def application do
            [applications: [:hackney]]
          end

      3. Run mix deps.get

      4. Quit and re-run this installer. It is perfectly safe to do so.
         This installer is idempotent.


      * Note: advanced users can define their own HTTP client if desired.
        Please see Timber.Transports.HTTP.Client for more details.
      """
      |> IOHelper.puts(:red)

      exit :shutdown
    end
  end
end
