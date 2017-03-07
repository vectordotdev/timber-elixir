defmodule Mix.Tasks.Timber.Install.WebFile do
  alias Mix.Tasks.Timber.Install.FileHelper

  def update!(file_path) do
    pattern = ~r/use Phoenix\.Controller/
    replacement = "\\0, log: false"
    FileHelper.replace_once!(file_path, pattern, replacement)
  end
end