defmodule Mix.Tasks.Timber.Install.PathHelper do
  alias Mix.Tasks.Timber.Install.{Config, IOHelper}

  # Ensures that the specified file exists. If it does not, it prompts
  # the user to enter the file path.
  def find(path_parts) when is_list(path_parts) do
    path = Config.path_client().join(path_parts)
    paths = Config.path_client().wildcard(path)

    case paths do
      [path] -> path

      [] ->
        case IOHelper.ask("We couldn't locate a #{path} file. Please enter the correct path") do
          v -> find([v])
        end

      _multiple ->
        case IOHelper.ask("We found multiple files matching #{path}. Please enter the correct path") do
          v -> find([v])
        end
    end
  end
end