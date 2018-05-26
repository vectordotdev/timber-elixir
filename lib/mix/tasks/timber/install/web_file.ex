defmodule Mix.Tasks.Timber.Install.WebFile do
  @moduledoc false

  alias Mix.Tasks.Timber.Install.FileHelper

  def update!(file_path, api) do
    content = FileHelper.read!(file_path)

    # Disable controller logging
    pattern = ~r/use Phoenix\.Controller/
    replacement = "\\0, log: false"

    content =
      FileHelper.replace_once!(
        content,
        pattern,
        replacement,
        "use Phoenix.Controller, log: false"
      )

    # Disable channel logging
    pattern = ~r/use Phoenix\.Channel/
    replacement = "\\0, log_join: false, log_handle_in: false"

    content =
      FileHelper.replace_once!(
        content,
        pattern,
        replacement,
        "use Phoenix.Channel, log_join: false, log_handle_in: false"
      )

    FileHelper.write!(file_path, content, api)
  end
end
