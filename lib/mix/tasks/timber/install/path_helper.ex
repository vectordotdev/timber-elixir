defmodule Mix.Tasks.Timber.Install.PathHelper do
  @moduledoc false

  alias Mix.Tasks.Timber.Install.{API, Config, IOHelper}

  # Ensures that the specified file exists. If it does not, it prompts
  # the user to enter the file path.
  def find(path_parts, api) when is_list(path_parts) do
    path = Config.path_client().join(path_parts)

    if Config.file_client().exists?(path) do
      path
    else
      API.event!(api, :file_not_found, %{path: path})

      case IOHelper.ask("We couldn't locate a #{path} file. Please enter the correct path") do
        v -> find([v], api)
      end
    end
  end
end