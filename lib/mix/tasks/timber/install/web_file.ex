defmodule Mix.Tasks.Timber.Install.WebFile do
  @moduledoc false

  alias Mix.Tasks.Timber.Install.FileHelper

  def update!(file_path, api) do
    pattern = ~r/use Phoenix\.Controller/
    replacement = "\\0, log: false"

    new_content =
      file_path
      |> FileHelper.read!()
      |> FileHelper.replace_once!(pattern, replacement, "use Phoenix.Controller, log: false")

    FileHelper.write!(file_path, new_content, api)
  end
end