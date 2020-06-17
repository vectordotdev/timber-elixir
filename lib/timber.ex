defmodule Timber do
  @moduledoc """
  This is the root module for interacting with the `:timber` library.

  It defines the primary public interface. Users should favor the methods
  defined in this module over their lower level counterparts. For example,
  instead of `Timber.LocalContact.add/1` use `Timber.add_context/1`.
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
  @spec add_context(map() | keyword()) :: :ok
  def add_context(data, location \\ :local)

  @doc """
  Adds context which will be included on log entries

  The second parameter indicates where you want the context to be
  stored. See `context_location` for more details.
  """
  @spec add_context(map() | keyword(), context_location) :: :ok
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
  defdelegate duration_ms(timer),
    to: Timber.Timer

  @doc """
  Gets the current context

  This is a merged representation of the `Timber.LocalContext` and `Timber.GlobalContext`.
  If you would like local or global context specifically you can pass `:global` or `:local`
  as the argument to this function.
  """
  @spec get_context() :: Context.t()
  def get_context(type \\ :all)

  def get_context(:all) do
    Map.merge(GlobalContext.get(), LocalContext.get())
  end

  def get_context(:local) do
    LocalContext.get()
  end

  def get_context(:global) do
    GlobalContext.get()
  end

  @doc false
  @deprecated "Please use delete_context/1 or delete_context/2"
  @spec remove_context_key(atom, context_location) :: :ok
  def remove_context_key(key, location \\ :local) do
    delete_context(key, location)
  end

  @doc ~S"""
  Used to time runtime execution.

  We highly recommend using this method as it uses the system monotonic time for
  accuracy.

  ## Example

      timer = Timber.start_timer()
      # .... do something
      duration_ms = Timber.duration_ms(timer)
      event = %{job_completed: %{duration_ms: duration_ms}}
      message = "Job completed in #{duration_ms}ms"
      Logger.info(message, event: event)

  """
  defdelegate start_timer,
    to: Timber.Timer,
    as: :start

  #
  # Utilility methods
  #
  # The following methods are used for internally throughout Timber and it's
  # dependent integration libraries.
  #

  # This method should be used for logging internal events.
  #
  # Because Timber is a logger it cannot log like a traditional library. This will create
  # a loop of debug messages. Instead we write to a configurable IO device that the user can
  # inspect, such as `STDOUT`, `STDERR`, a file.
  @doc false
  def log(level, message_fun) do
    Timber.Config.debug_io_device()
    |> log(level, message_fun)
  end

  @doc false
  def log(nil, _level, _message_fun) do
    false
  end

  def log(io_device, level, message_fun) when is_function(message_fun) do
    level = level |> Atom.to_string() |> String.upcase()
    message = message_fun.()

    IO.puts(io_device, [level, ": ", message])
  end

  # Formats a duration, in milliseonds, to a human friendly representation
  @doc false
  def format_duration_ms(duration_ms) when is_integer(duration_ms),
    do: [Integer.to_string(duration_ms), "ms"]

  def format_duration_ms(duration_ms) when is_float(duration_ms) and duration_ms >= 1,
    do: [:erlang.float_to_binary(duration_ms, decimals: 2), "ms"]

  def format_duration_ms(duration_ms) when is_float(duration_ms) and duration_ms < 1,
    do: [:erlang.float_to_binary(duration_ms * 1000, decimals: 0), "µs"]

  # Convenience function for formatting durations into a human readable string.
  @doc false
  def format_time_ms(time_ms) when is_integer(time_ms),
    do: [Integer.to_string(time_ms), "ms"]

  def format_time_ms(time_ms) when is_float(time_ms) and time_ms >= 1,
    do: [:erlang.float_to_binary(time_ms, decimals: 2), "ms"]

  def format_time_ms(time_ms) when is_float(time_ms) and time_ms < 1,
    do: [:erlang.float_to_binary(time_ms * 1000, decimals: 0), "µs"]
end
