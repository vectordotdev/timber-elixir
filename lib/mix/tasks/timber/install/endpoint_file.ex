defmodule Mix.Tasks.Timber.Install.EndpointFile do
  alias Mix.Tasks.Timber.Install.FileHelper

  def update!(file_path) do
    pattern = ~r/( *)plug [^\n\r]*.Router/
    replacement =
      "\\1# Add Timber plugs for capturing HTTP context and events\n" <>
        "\\1plug Timber.Integrations.ContextPlug\n" <>
        "\\1plug Timber.Integrations.EventPlug\n\n\\0"

    FileHelper.replace_once!(file_path, pattern, replacement, "plug Timber.Integrations")
  end
end