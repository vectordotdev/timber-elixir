defmodule Mix.Tasks.Timber.Install.Project do
  @moduledoc false

  defstruct [:config_file_path, :endpoint_file_path, :endpoint_module_name, :mix_name,
    :module_name, :repo_module_name, :web_file_path]

  alias Mix.Tasks.Timber.Install.{FileHelper, IOHelper, PathHelper}

  @module_name_regex ~r/defmodule (.*?) do/

  def new(api) do
    config_file_path = get_config_file_path(api)
    endpoint_file_path = get_endpoint_file_path(api)
    endpoint_module_name = get_endpoint_module_name(endpoint_file_path)
    mix_name = get_mix_name(api)
    module_name = Macro.camelize(mix_name)
    repo_file_path = get_repo_file_path(api)
    repo_module_name = get_repo_module_name(repo_file_path)
    web_file_path = get_web_file_path(api)

    %__MODULE__{
      config_file_path: config_file_path,
      endpoint_file_path: endpoint_file_path,
      endpoint_module_name: endpoint_module_name,
      mix_name: mix_name,
      module_name: module_name,
      repo_module_name: repo_module_name,
      web_file_path: web_file_path
    }
  end

  defp get_mix_name(api) do
    case File.cwd() do
      {:ok, cwd} ->
        cwd
        |> Path.split()
        |> List.last()
        |> String.replace("-", "_")

      {:error, _reason} ->
        IOHelper.ask("What's the name of your application? (please use snake_case, ex: my_app)",
          api)
    end
  end

  defp get_config_file_path(api) do
    file_explanation = "We need this to link config/timber.exs"
    PathHelper.find(["config", "config.exs"], file_explanation, api)
  end

  defp get_endpoint_file_path(api) do
    if Code.ensure_loaded?(Phoenix) do
      file_explanation = "We need this so that we can install the Timber plugs."
      PathHelper.find(["{lib,web}", "**", "endpoint.ex"], file_explanation, api,
        check_for_umbrella: true, contents_filter: "use Phoenix.Endpoint")
    else
      nil
    end
  end

  defp get_endpoint_module_name(nil), do: nil

  defp get_endpoint_module_name(endpoint_file_path) do
    file_contents = FileHelper.read!(endpoint_file_path)
    get_module_name(file_contents)
  end

  defp get_repo_file_path(api) do
    if Code.ensure_loaded?(Ecto) do
      file_explanation = "We need this to capture Ecto log events"
      PathHelper.find(["{lib,web}", "**", "repo.ex"], file_explanation, api,
        check_for_umbrella: true, contents_filter: "use Ecto.Repo")
    else
      nil
    end
  end

  defp get_repo_module_name(nil), do: nil

  defp get_repo_module_name(repo_file_path) do
    file_contents = FileHelper.read!(repo_file_path)
    get_module_name(file_contents)
  end

  defp get_web_file_path(api) do
    if Code.ensure_loaded?(Phoenix) do
      file_explanation = "We need this to disable the default Phoenix controller logging"
      PathHelper.find(["web", "web.ex"], file_explanation, api, check_for_umbrella: true,
        contents_filter: "use Phoenix.Controller")
    else
      nil
    end
  end

  defp get_module_name(file_contents) do
    case Regex.run(@module_name_regex, file_contents) do
      [_contents, module_name] -> module_name
      _ -> nil
    end
  end
end