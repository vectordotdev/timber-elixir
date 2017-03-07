defmodule Mix.Tasks.Timber.Install.FileHelper do
  alias __MODULE__.FileWritingError
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

  def replace_once!(path, pattern, replacement) do
    case Config.file_client().read(path) do
      {:ok, contents} ->
        if String.contains?(contents, replacement) do
          :ok

        else
          new_contents = String.replace(contents, pattern, replacement)
          write!(path, new_contents)
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