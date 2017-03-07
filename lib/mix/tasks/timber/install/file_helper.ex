defmodule Mix.Tasks.Timber.Install.FileHelper do
  alias __MODULE__.{FileReplacePatternError, FileWritingError}
  alias Mix.Tasks.Timber.Install.Config

  def append_once!(path, contents) do
    case Config.file_client().read(path) do
      {:ok, current_contents} ->
        trimmed_contents = String.trim(contents)

        if String.contains?(current_contents, trimmed_contents) do
          :ok
        else
          case Config.file_client().open(path, [:append]) do
            {:ok, file} ->
              result = Config.io_client().binwrite(file, contents)
              Config.file_client().close(file)
              result

            {:error, reason} -> raise(FileWritingError, path: path, reason: reason)
          end
        end

      {:error, reason} -> raise(FileWritingError, path: path, reason: reason)
    end
  end

  def replace_once!(path, pattern, replacement, contains_pattern) do
    case Config.file_client().read(path) do
      {:ok, contents} ->
        if String.contains?(contents, contains_pattern) do
          :ok

        else
          new_contents = String.replace(contents, pattern, replacement)
          if String.contains?(contents, contains_pattern) do
            write!(path, new_contents)
          else
            raise(FileReplacePatternError, path: path, pattern: contains_pattern)
          end
        end

      {:error, reason} -> raise(FileWritingError, path: path, reason: reason)
    end
  end

  def write!(path, contents) do
    case Config.file_client().open(path, [:write]) do
      {:ok, file} ->
        result = Config.io_client().binwrite(file, contents)
        Config.file_client().close(file)

        case result do
          :ok -> :ok
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
      path = Keyword.fetch!(opts, :path)
      pattern = Keyword.fetch!(opts, :pattern)
      message =
        """
        Uh oh! We had a problem updating #{path}. The pattern
        #{pattern} was not found after writing!
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