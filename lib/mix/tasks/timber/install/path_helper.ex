defmodule Mix.Tasks.Timber.Install.PathHelper do
  @moduledoc false

  alias Mix.Tasks.Timber.Install.{API, Config, IOHelper}

  # Ensures that the specified file exists. If it does not, it prompts
  # the user to enter the file path.
  def find(path_parts, file_explanation, api) when is_list(path_parts) do
    path = Config.path_client().join(path_parts)
    file_name = Enum.at(path_parts, -1)
    prompt_message =
      """
      If you prefer, you can skip this and manually install later following
      these instructions: https://timber.io/docs/elixir/installation/manual-installation/

      Please enter the correct relative path, or type 'skip' to skip"
      """

    case Config.path_client().wildcard(path) do
      [] ->
        API.event!(api, :file_not_found, %{path: path})

        prompt =
          """
          We couldn't find your #{file_name} file.

          #{file_explanation}

          #{prompt_message}
          """

        case IOHelper.ask(prompt, api) do
          v -> find([v], file_explanation, api)
        end

      [file_path] ->
        API.event!(api, :file_found, %{path: path})

        file_path

      file_paths ->
        API.event!(api, :multiple_files_found, %{path: path})

        file_paths_list = Enum.join(file_paths, "\n")

        prompt =
          """
          Whoa! We found multiple #{file_name} files:

          #{file_paths_list}

          #{file_explanation}

          #{prompt_message}
          """

        case IOHelper.ask(prompt, api) do
          v -> find([v], file_explanation, api)
        end
    end
  end
end