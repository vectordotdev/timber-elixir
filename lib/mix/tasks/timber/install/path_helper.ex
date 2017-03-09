defmodule Mix.Tasks.Timber.Install.PathHelper do
  alias Mix.Tasks.Timber.Install.{Config, Event, IOHelper}

  # Ensures that the specified file exists. If it does not, it prompts
  # the user to enter the file path.
  def find(path_parts, session_id, api_key) when is_list(path_parts) do
    path = Config.path_client().join(path_parts)

    if Config.file_client().exists?(path) do
      path
    else
      Event.send!(:file_not_found, session_id, api_key, data: %{path: path})

      case IOHelper.ask("We couldn't locate a #{path} file. Please enter the correct path") do
        v -> find([v], session_id, api_key)
      end
    end
  end
end