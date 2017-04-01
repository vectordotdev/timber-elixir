defmodule Mix.Tasks.Timber.Install.EndpointFile do
  @moduledoc false

  alias Mix.Tasks.Timber.Install.FileHelper

  def update!(file_path, api) do
    router_pattern = ~r/( *)plug [^\n\r]*.Router/
    router_replacement =
      "\\1# Add Timber plugs for capturing HTTP context and events\n" <>
        "\\1plug Timber.Integrations.ContextPlug\n" <>
        "\\1plug Timber.Integrations.EventPlug\n\n\\0"

    logger_pattern = ~r/( *)plug Plug\.Logger\n?/

    new_contents =
      file_path
      |> FileHelper.read!()
      |> FileHelper.replace_once!(router_pattern, router_replacement, "plug Timber.Integrations")
      |> FileHelper.remove_once!(logger_pattern)

    FileHelper.write!(file_path, new_contents, api)
  end
end