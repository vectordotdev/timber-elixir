defmodule Mix.Tasks.Timber.Install.PathHelper do
  alias Mix.Tasks.Timber.Install.{Config, IOHelper}

  # Ensures that the specified file exists. If it does not, it prompts
  # the user to enter the file path.
  def find(path_parts) when is_list(path_parts) do
    path = Config.path_client().join(path_parts)

    if Config.file_client().exists?(path) do
      path
    else
      case IOHelper.ask("We couldn't locate a #{path} file. Please enter the correct path") do
        v -> find([v])
      end
    end
  end
end