defmodule Mix.Tasks.Timber.Install.FileHelper do
  @moduledoc false

  alias __MODULE__.{FileReadingError, FileReplacePatternError, FileWritingError}
  alias Mix.Tasks.Timber.Install.{API, Config}

  def append_once!(path, contents, contains_pattern, api) do
    case Config.file_client().read(path) do
      {:ok, current_contents} ->
        if String.contains?(current_contents, contains_pattern) do
          :ok
        else
          case Config.file_client().open(path, [:append]) do
            {:ok, file} ->
              result = Config.io_client().binwrite(file, contents)
              Config.file_client().close(file)

              API.event!(api, :file_written, %{path: path})

              result

            {:error, reason} -> raise(FileWritingError, path: path, reason: reason)
          end
        end

      {:error, reason} -> raise(FileWritingError, path: path, reason: reason)
    end
  end

  def dir?(path) do
    Config.file_client().dir?(path)
  end

  def read!(path) do
    case Config.file_client().read(path) do
      {:ok, contents} -> contents
      {:error, reason} -> raise(FileReadingError, path: path, reason: reason)
    end
  end

  def remove_once!(contents, pattern) do
    String.replace(contents, pattern, "")
  end

  def replace_once!(contents, pattern, replacement, contains_pattern) do
    if String.contains?(contents, contains_pattern) do
      contents

    else
      new_contents = String.replace(contents, pattern, replacement)

      if String.contains?(new_contents, contains_pattern) do
        new_contents
      else
        raise(FileReplacePatternError, pattern: contains_pattern)
      end
    end
  end

  def write!(path, contents, api) do
    case Config.file_client().open(path, [:write]) do
      {:ok, file} ->
        result = Config.io_client().binwrite(file, contents)
        Config.file_client().close(file)

        case result do
          :ok ->
            API.event!(api, :file_written, %{path: path})
            :ok

          {:error, reason} -> raise(FileWritingError, path: path, reason: reason)
        end

      {:error, reason} -> raise(FileWritingError, path: path, reason: reason)
    end
  end

  #
  # Errors
  #

  defmodule FileReplacePatternError do
    defexception [:message]

    def exception(opts) do
      pattern = Keyword.fetch!(opts, :pattern)
      message =
        """
        Uh oh! We had a problem updating a file. The pattern
        #{pattern} was not found after writing!
        """
      %__MODULE__{message: message}
    end
  end

  defmodule FileReadingError do
    defexception [:message]

    def exception(opts) do
      path = Keyword.fetch!(opts, :path)
      reason = Keyword.fetch!(opts, :reason)
      message =
        """
        Uh oh! We had a problem reading #{path}:

        #{reason}
        """
      %__MODULE__{message: message}
    end
  end

  defmodule FileWritingError do
    defexception [:message]

    def exception(opts) do
      path = Keyword.fetch!(opts, :path)
      reason = Keyword.fetch!(opts, :reason)
      message =
        """
        Uh oh! We had a problem writing to #{path}:

        #{reason}
        """
      %__MODULE__{message: message}
    end
  end
end