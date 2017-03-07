defmodule Mix.Tasks.Timber.Install.Application do
  alias Mix.Tasks.Timber.Install.{Config, IOHelper}

  defstruct [:api_key, :config_file_path, :endpoint_file_path, :endpoint_module_name,
    :mix_name, :module_name, :name, :platform_type, :repo_file_path, :repo_module_name, :subdomain]

  def new(api_key) do
    encoded_api_key = Base.encode64(api_key)
    headers = %{"Authorization" => "Basic #{encoded_api_key}"}
    response = Config.http_client().request("GET", "/installer/application", headers)

    case response do
      {:ok, %{"name" => name, "subdomain" => subdomain, "platform_type" => platform_type,
        "api_key" => api_key}}
      ->
        mix_name = get_mix_name()
        module_name = Macro.camelize(mix_name)
        config_file_path = PathHelper.find(["config", "config.exs"])

        endpoint_file_path =
          if Timber.Integrations.phoenix?(),
            do: PathHelper.find(["lib", name, "endpoint.ex"]),
            else: nil

        # TODO: check that this module actually exists
        endpoint_module_name =
          if endpoint_file_path,
            do: "#{module_name}.Endpoint",
            else: nil

        repo_file_path =
          if Timber.Integrations.ecto?(),
            do: PathHelper.find(["lib", name, "repo.ex"]),
            else: nil

        # TODO: check that this module actually exists
        repo_module_name =
          if repo_file_path,
            do: "#{module_name}.Repo",
            else: nil

        application = %__MODULE__{
          name: name,
          subdomain: subdomain,
          platform_type: platform_type,
          api_key: api_key,
          mix_name: mix_name,
          module_name: module_name,
          config_file_path: config_file_path,
          endpoint_file_path: endpoint_file_path,
          endpoint_module_name: endpoint_module_name,
          repo_file_path: repo_file_path,
          repo_module_name: repo_module_name
        }

        {:ok, application}

      {:error, reason} -> {:error, reason}
    end
  end

  defp get_mix_name do
    case File.cwd() do
      {:ok, cwd} ->
        cwd
        |> Path.split()
        |> List.last()

      {:error, _reason} ->
        IOHelper.ask("What's the name of your application? (please use snake_case, ex: my_app)")
    end
  end
end