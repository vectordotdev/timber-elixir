defmodule Mix.Tasks.Timber.Install.Application do
  alias __MODULE__.MalformedApplicationPayload
  alias Mix.Tasks.Timber.Install.{Config, IOHelper, Messages, PathHelper}

  defstruct [:api_key, :config_file_path, :endpoint_file_path, :endpoint_module_name,
    :heroku_drain_url, :mix_name, :module_name, :name, :platform_type,
    :repo_module_name, :slug, :web_file_path]

  def new!(api_key) do
    response = Config.http_client().request!(:get, "/installer/application", api_key: api_key)

    case response do
      {200, %{"api_key" => api_key, "heroku_drain_url" => heroku_drain_url, "name" => name,
        "platform_type" => platform_type, "slug" => slug}}
      ->
        mix_name = get_mix_name()
        module_name = Macro.camelize(mix_name)
        config_file_path = PathHelper.find(["config", "config.exs"])

        endpoint_file_path =
          if Timber.Integrations.phoenix?(),
            do: PathHelper.find(["lib", mix_name, "endpoint.ex"]),
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
            do: PathHelper.find(["web", "web.ex"]),
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

  def wait_for_logs(application, iteration \\ 0)

  def wait_for_logs(%{api_key: api_key, platform_type: platform_type} = application, iteration) do
    rem = rem(iteration, 4)

    IO.ANSI.format(["\r", :clear_line, wait_for_logs_message(platform_type), String.duplicate(".", rem), "\e[u"])
    |> IOHelper.write()

    response = Config.http_client().request!(:get, "/installer/has_logs", api_key: api_key)

    case response do
      {202, _body} ->
        :timer.sleep(1000)
        wait_for_logs(application, iteration + 1)

      {204, _body} ->
        "  " <> Messages.success()
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