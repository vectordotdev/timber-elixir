defmodule Mix.Tasks.Timber.Install.PathHelper do
  @moduledoc false

  alias Mix.Tasks.Timber.Install.{API, Config, FileHelper, IOHelper}

  # Ensures that the specified file exists. If it does not, it prompts
  # the user to enter the file path.
  def find(path_parts, file_explanation, api, opts \\ []) when is_list(path_parts) do
    # Check to see if we're in an umbrella app
    path_parts =
      if Keyword.get(opts, :check_for_umbrella) do
        if FileHelper.dir?("apps") do
          ["apps", "**"] ++ path_parts
        else
          path_parts
        end
      else
        path_parts
      end

    path = Config.path_client().join(path_parts)
    file_name = Enum.at(path_parts, -1)

    missing_file_prompt_message =
      """
      If you prefer, you can skip this and manually install later following
      these instructions: https://timber.io/docs/elixir/installation/manual-installation/

      Please enter the correct relative path for the '#{IOHelper.colorize(file_name, :blue)}' file (or type 'skip' to skip)
      """

    case Config.path_client().wildcard(path) do
      [] ->
        API.event!(api, :file_not_found, %{path: path})

        prompt =
          """

          #{IOHelper.colorize("We couldn't find a '#{file_name}' file.", :yellow)}

          #{file_explanation}

          #{missing_file_prompt_message}
          """
          |> String.trim_trailing()

        case IOHelper.ask(prompt, api) do
          "skip" -> nil
          v -> find([v], file_explanation, api)
        end

      [file_path] ->
        API.event!(api, :file_found, %{path: path})

        file_path

      file_paths ->
        contents_filter = Keyword.get(opts, :contents_filter)

        file_paths =
          if contents_filter do
            Enum.filter(file_paths, fn file_path ->
              contents = FileHelper.read!(file_path)
              String.contains?(contents, contents_filter)
            end)
          else
            file_paths
          end

        case file_paths do
          [file_path] -> file_path

          file_paths ->
            API.event!(api, :multiple_files_found, %{path: path})

            file_paths_list = Enum.join(file_paths, "\n")

            prompt =
              """

              #{IOHelper.colorize("Whoa! We found multiple #{file_name} files:", :yellow)}

              #{IOHelper.colorize(file_paths_list, :blue)}

              #{file_explanation}

              #{missing_file_prompt_message}
              """
              |> String.trim_trailing()

            case IOHelper.ask(prompt, api) do
              v -> find([v], file_explanation, api)
            end
        end
    end
  end
end