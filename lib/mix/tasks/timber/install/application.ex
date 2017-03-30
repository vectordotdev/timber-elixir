defmodule Mix.Tasks.Timber.Install.Application do
  @moduledoc false

  alias __MODULE__.MalformedApplicationPayload
  alias Mix.Tasks.Timber.Install.{API, IOHelper, PathHelper}

  defstruct [:api_key, :config_file_path, :endpoint_file_path, :endpoint_module_name,
    :heroku_drain_url, :mix_name, :module_name, :name, :platform_type,
    :repo_module_name, :slug, :web_file_path]

  def new!(api) do
    response = API.application!(api)

    case response do
      {200, %{"api_key" => api_key, "heroku_drain_url" => heroku_drain_url, "name" => name,
        "platform_type" => platform_type, "slug" => slug}}
      ->
        mix_name = get_mix_name()
        module_name = Macro.camelize(mix_name)

        file_explanation = "We need this file so that we can link the config/timber.exs file at the very bottom."
        config_file_path = PathHelper.find(["config", "config.exs"], file_explanation, api)


        file_explanation = "We need this file so that we can add the Timber plugs."
        endpoint_file_path =
          if Code.ensure_loaded?(Phoenix),
            do: PathHelper.find(["lib", "**", "endpoint.ex"], file_explanation api),
            else: nil

        # TODO: check that this module actually exists
        endpoint_module_name =
          if endpoint_file_path,
            do: "#{module_name}.Endpoint",
            else: nil

        # TODO: check that this module actually exists
        repo_module_name =
          if Code.ensure_loaded?(Ecto),
            do: "#{module_name}.Repo",
            else: nil

        web_file_path =
          if Code.ensure_loaded?(Phoenix),
            do: PathHelper.find(["web", "**", "web.ex"], api),
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
