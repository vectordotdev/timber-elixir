defmodule Timber do
  @moduledoc """
  The functions in this module are high level convenience functions instended to define
  the broader / public API of the Timber library. It is recommended to use these functions
  instead of their deeper counterparts.
  """

  alias Timber.Context
  alias Timber.LocalContext
  alias Timber.GlobalContext

  #
  # Typespecs
  #

  @typedoc """
  The target context to perform the operation.

    - `:global` - This stores the context at a global level, meaning
      it will be present on every log line, regardless of which process
      generates the log line.
    - `:local` - This stores the context in the Logger Metadata which
      is local to the process
  """
  @type context_location :: :local | :global

  #
  # API
  #

  @doc """
  Adds Timber context to the current process

  See `add_context/2`
  """
  @spec add_context(Context.element()) :: :ok
  def add_context(data, location \\ :local)

  @doc """
  Adds context which will be included on log entries

  The second parameter indicates where you want the context to be
  stored. See `context_location` for more details.
  """
  @spec add_context(Context.element(), context_location) :: :ok
  def add_context(data, :local) do
    LocalContext.add(data)
  end

  def add_context(data, :global) do
    GlobalContext.add(data)
  end

  @doc """
  Deletes a key from Timber context on the current process.

  See `delete_context/2`
  """
  @spec delete_context(atom) :: :ok
  def delete_context(key, location \\ :local)

  @doc """
  Deletes a context key.

  The second parameter indicates which context you want the key to be removed from.
  """
  @spec delete_context(atom, context_location) :: :ok
  def delete_context(key, :local) do
    LocalContext.delete(key)
  end

  def delete_context(key, :global) do
    GlobalContext.delete(key)
  end

  @doc """
  Captures the duration in fractional milliseconds since the timer was started. See
  `start_timer/0`.
  """
  defdelegate duration_ms(timer), to: Timber.Timer

  @doc false
  @deprecated "Please use delete_context/1 or delete_context/2"
  @spec remove_context_key(atom, context_location) :: :ok
  def remove_context_key(key, location \\ :local) do
    delete_context(key, location)
  end

  @doc """
  Used to time runtime execution. For example, when timing a `Timber.Events.HTTPResponseEvent`:

  ```elixir
  timer = Timber.start_timer()
  # .... make request
  time_ms = Timber.duration_ms(timer)
  event = HTTPResponseEvent.new(status: 200, time_ms: time_ms)
  message = HTTPResponseEvent.message(event)
  Logger.info(message, event: event)
  ```

  """
  defdelegate start_timer, to: Timber.Timer, as: :start

  #
  # Utilility methods
  # The following methods are used for internally throughout Timber and it's
  # dependent integration libraries.
  #

  @doc false
  def debug(message_fun) do
    Timber.Config.debug_io_device()
    |> debug(message_fun)
  end

  @doc false
  def debug(nil, _message_fun) do
    false
  end

  def debug(io_device, message_fun) when is_function(message_fun) do
    IO.write(io_device, message_fun.())
  end

  # Convenience function for encoding data to JSON. This is necessary to allow for
  # configurable JSON parsers.
  @doc false
  def encode_to_json(data) do
    Jason.encode_to_iodata(data)
  end

  # Convenience function that attempts to encode the provided argument to JSON.
  # If the encoding fails a `nil` value is returned. If you want the actual error
  # please use `encode_to_json/1`.
  @doc false
  def try_encode_to_json(data) do
    case encode_to_json(data) do
      {:ok, json} -> json
      {:error, _error} -> nil
    end
  end
end
