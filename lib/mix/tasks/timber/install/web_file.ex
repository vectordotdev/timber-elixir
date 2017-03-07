defmodule Mix.Tasks.Timber.Install.WebFile do
  alias Mix.Tasks.Timber.Install.FileHelper

  def update(file_path) do
    pattern = ~r/use Phoenix\.Controller/
    replacement = "\\0, log: false"

    case FileHelper.replace_once(file_path, pattern, replacement) do
      :ok -> :ok

      {:error, reason} ->
        {:error, "Uh oh, we had a problem writing to #{file_path}: #{reason}"}
    end
  end
end