defmodule Mix.Tasks.Timber.Install.EndpointFile do
  alias Mix.Tasks.Timber.Install.FileHelper

  def update(file_path) do
    pattern = ~r/( *)plug ElixirPhoenixExampleApp\.Router/
    replacement =
      "\\1# Add Timber plugs for capturing HTTP context and events\n" <>
        "\\1plug Timber.Integrations.ContextPlug\n" <>
        "\\1plug Timber.Integrations.EventPlug\n\n\\0"

    case FileHelper.replace_once(file_path, pattern, replacement) do
      :ok -> :ok

      {:error, reason} ->
        {:error, "Uh oh, we had a problem writing to #{file_path}: #{reason}"}
    end
  end
end