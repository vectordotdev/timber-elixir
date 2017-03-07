defmodule Mix.Tasks.Timber.Install.FileHelper do
  alias Mix.Tasks.Timber.Install.Config

  # Ensures that the specified file exists. If it does not, it prompts
  # the user to enter the file path.
  defp find(path_parts) when is_list(path_parts) do
    file_paths =
      path
      |> Config.path_client().join()
      |> Config.path_client().wildcard()

    case paths do
      [path] -> path

      [] ->
        case ask("We couldn't locate a #{path} file. Please enter the correct path") do
          v -> find_file(v)
        end

      _multiple ->
        case ask("We found multiple files matching #{path}. Please enter the correct path") do
          v -> find_file(v)
        end
    end
  end
end