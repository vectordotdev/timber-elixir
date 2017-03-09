defmodule Mix.Tasks.Timber.Install.Application do
  alias __MODULE__.MalformedApplicationPayload
  alias Mix.Tasks.Timber.Install.{Config, Event, IOHelper, Messages, PathHelper}

  defstruct [:api_key, :config_file_path, :endpoint_file_path, :endpoint_module_name,
    :heroku_drain_url, :mix_name, :module_name, :name, :platform_type,
    :repo_module_name, :slug, :web_file_path]

  def new!(session_id, api_key) do
    response = Config.http_client().request!(session_id, :get, "/installer/application",
      api_key: api_key)

    case response do
      {200, %{"api_key" => api_key, "heroku_drain_url" => heroku_drain_url, "name" => name,
        "platform_type" => platform_type, "slug" => slug}}
      ->
        mix_name = get_mix_name()
        module_name = Macro.camelize(mix_name)
        config_file_path = PathHelper.find(["config", "config.exs"], session_id, api_key)

        endpoint_file_path =
          if Timber.Integrations.phoenix?(),
            do: PathHelper.find(["lib", mix_name, "endpoint.ex"], session_id, api_key),
            else: nil

        # TODO: check that this module actually exists
        endpoint_module_name =
          if endpoint_file_path,
            do: "#{module_name}.Endpoint",
            else: nil

        # TODO: check that this module actually exists
        repo_module_name =
          if Timber.Integrations.ecto?(),
            do: "#{module_name}.Repo",
            else: nil

        web_file_path =
          if Timber.Integrations.ecto?(),
            do: PathHelper.find(["web", "web.ex"], session_id, api_key),
            else: nil

        application = %__MODULE__{
          api_key: api_key,
          config_file_path: config_file_path,
          endpoint_file_path: endpoint_file_path,
          endpoint_module_name: endpoint_module_name,
          heroku_drain_url: heroku_drain_url,
          mix_name: mix_name,
          module_name: module_name,
          name: name,
          platform_type: platform_type,
          repo_module_name: repo_module_name,
          slug: slug,
          web_file_path: web_file_path
        }

        application

      {200, payload} -> raise(MalformedApplicationPayload, payload: payload)
    end
  end

  defp get_mix_name do
    case File.cwd() do
      {:ok, cwd} ->
        cwd
        |> Path.split()
        |> List.last()
        |> String.replace("-", "_")

      {:error, _reason} ->
        IOHelper.ask("What's the name of your application? (please use snake_case, ex: my_app)")
    end
  end

  def wait_for_logs(application, session_id, iteration \\ 0)

  def wait_for_logs(%{api_key: api_key, platform_type: platform_type} = application, session_id, iteration) do
    IO.ANSI.format(["\r", :clear_line])
    |> IOHelper.write()

    platform_type
    |> wait_for_logs_message()
    |> Messages.action_starting()
    |> IOHelper.write()

    response = Config.http_client().request!(session_id, :get, "/installer/has_logs",
      api_key: api_key)

    case response do
      {202, _body} ->
        rem = rem(iteration, 3)

        spinner(rem)
        |> IOHelper.write()

        if iteration == 30 do
          Event.send!(:excessive_log_waiting, session_id, api_key)
        end

        if iteration > 30 do
          " (Having trouble? We'd love to help: support@timber.io)"
          |> IOHelper.write()
        end

        :timer.sleep(1000)

        wait_for_logs(application, session_id, iteration + 1)

      {204, _body} ->
        Messages.success()
        |> IOHelper.puts(:green)

        :ok
    end
  end

  defp wait_for_logs_message("heroku") do
    "Waiting for logs (Heroku can sometimes take a minute)"
  end

  defp wait_for_logs_message(_platform) do
    "Waiting for logs (this can sometimes take a minute)"
  end

  defp spinner(0), do: "-"
  defp spinner(1), do: "\\"
  defp spinner(2), do: "/"

  #
  # Errors
  #

  defmodule MalformedApplicationPayload do
    defexception [:message]

    def exception(opts) do
      payload = Keyword.fetch!(opts, :payload)
      message =
        """
        Uh oh! We received a malformed application payload:

        #{inspect(payload)}
        """
      %__MODULE__{message: message}
    end
  end
end