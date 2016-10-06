defmodule Timber.Transports.IODevice do
  @moduledoc """
  The IODevice transport mechanism allows you to log directly to
  `stdout` (default; see below) or any other IODevice of your choice

  ## Default Output
  
  The suggestion above is that the default configuration of this
  transport will log to `stdout` by default. This is true in most
  cases, but it is misleadingly generic. The output will actually be
  sent to the process registered under the name `:user`. This process
  is registered by the VM at startup and is designed to handle IO
  redirection. In other words, `:user` is the middleman that will
  _typically_ write to `stdout` _unless_ you have additional configuration
  that would make it redirect output elsewhere.

  ## Synchronicity
  
  The IODevice transport will output messages asynchronously to the IO device
  using standard BEAM process messaging. After sending output to be written,
  the transport will begin buffering all new log events. When the remote IO
  device responds that the output was successful, the buffer will be flushed
  to the IO device, repeating the process. If the buffer reaches its maximum
  size, the transport will switch to simulated synchronous mode, blocking
  until the IO device sends a response about the last write operation.

  ## Transport Configuration Options

  The following options are available when configuring the IODevice logger:

  #### `max_buffer_size`
  
  The maximum number of log entries that the log event buffer will hold until
  the transport switchs to synchronous mode. This value should be tuned to
  accomodate your system's IO capability versus the amount of logging you
  perform.

  _Defaults to 100._
  """

  @behaviour Timber.Transport

  alias Timber.LogEntry
  alias __MODULE__.BadDeviceError

  @typep t :: %__MODULE__{
    ref: reference | nil,
    device: nil | IO.device,
    output: nil | IO.chardata,
    buffer_size: non_neg_integer,
    max_buffer_size: pos_integer,
    buffer: [] | [IO.chardata]
  }

  defstruct device: nil,
            ref: nil,
            output: nil,
            buffer_size: 0,
            max_buffer_size: 100,
            buffer: []

  @doc false
  @spec init(Keyword.t) :: {:ok, t}
  def init(config) do
    filename = Keyword.get(config, :file, :no_file)

    with {:ok, device} <- get_device(filename),
         {:ok, state} <- configure(config, %__MODULE__{device: device}),
         do: {:ok, state}
  end

  @spec get_device(String.t | :no_file) :: {:ok, IO.device} | {:error, Exception.t}
  defp get_device(:no_file) do
    if Process.whereis(:user) do
      {:ok, :user}
    else
      error = BadDeviceError.exception([type: :user, reason: :not_registered])
      {:error, error}
    end
  end

  defp get_device(filename) do
    case File.open(filename, [:append, :utf8]) do
      {:ok, device} -> {:ok, device}
        {:ok, device}
      {:error, reason} ->
        exception_metadata = [
          type: :file,
          path: filename,
          reason: reason
        ]

        error = BadDeviceError.exception(exception_metadata)
        {:error, error}
    end
  end

  @doc false
  @spec configure(Keyword.t, t) :: {:ok, t}
  def configure(_options, state) do
    {:ok, state}
  end

  @doc false
  @spec write(LogEntry.t, t) :: {:ok, t}
  def write(%LogEntry{dt: timestamp, level: level, message: message} = log_entry, state) do
    device = state.device
    ref = state.ref
    buffer_size = state.buffer_size
    max_buffer_size = state.max_buffer_size

    level_b = Atom.to_string(level)

    encoded_context = LogEntry.to_json_string!(log_entry, only: [:context])

    output = [timestamp, " [", level_b, "] ", message, " @timberio ", encoded_context, "\n"]

    cond do
      is_nil(ref) ->
        ref = write_async(device, output)
        new_state = %{state | ref: ref, output: output}
        {:ok, new_state}
      buffer_size < max_buffer_size ->
        # buffer while the other stuff finishes writing
        new_state = write_buffer(output, state)
        {:ok, new_state}
      buffer_size === max_buffer_size ->
        # sync mode
        new_state =
          write_buffer(output, state)
          |> wait_for_device()

        {:ok, new_state}
    end
  end

  @spec write_buffer(IO.chardata, t) :: t
  defp write_buffer(output, state) do
    buffer = state.buffer
    buffer_size = state.buffer_size
    %__MODULE__{state | buffer: [buffer | output], buffer_size: buffer_size + 1}
  end

  @spec write_async(IO.device, IO.chardata) :: reference | no_return
  defp write_async(:user, output) do
    case Process.whereis(:user) do
      device when is_pid(device) ->
        write_async(device, output)
      nil ->
        raise BadDeviceError, [type: :user, reason: :not_registered]
    end
  end

  defp write_async(device, output) do
    ref = Process.monitor(device)
    send(device, {:io_request, self(), ref, {:put_chars, :unicode, output}})
    ref
  end

  @spec wait_for_device(t) :: t | no_return
  defp wait_for_device(%{ref: nil} = state) do
    state
  end

  defp wait_for_device(%{ref: ref} = state) do
    receive do
      {:io_reply, ^ref, :ok} ->
        handle_io_reply(:ok, state)
      {:io_reply, ^ref, error} ->
        handle_io_reply(error, state)
        |> wait_for_device()
      {:DOWN, ^ref, _, _pid, _reason} ->
        raise "Device down" #DeviceDown
    end
  end

  @doc false
  @spec handle_info(any, t) :: {:ok, t} | no_return
  def handle_info({:io_reply, ref, msg}, %{ref: ref} = state) do
    {:ok, handle_io_reply(msg, state)}
  end

  def handle_info({:DOWN, ref, _, _pid, _reason}, %{ref: ref}) do
    raise "Device down" #DeviceDown
  end

  def handle_info(_, state) do
    {:ok, state}
  end

  @spec handle_io_reply(:ok, t) :: t
  defp handle_io_reply(:ok, %{ref: ref} = state) do
    Process.demonitor(ref, [:flush])
    flush_buffer(%{state | ref: nil, output: nil})
  end

  @spec flush_buffer(t) :: t
  defp flush_buffer(%{ref: ref} = state) when not is_nil(ref) do
    wait_for_device(state)
    |> flush_buffer()
  end

  defp flush_buffer(%{buffer_size: 0, buffer: []} = state) do
    state
  end

  defp flush_buffer(state) do
    %{device: device, buffer: buffer} = state
    ref = write_async(device, buffer)
    %__MODULE__{state | ref: ref, buffer: [], buffer_size: 0, output: buffer}
  end

  @doc false
  @spec flush(t) :: t
  # If the ref is `nil` then the system is not currently
  # writing any data.
  def flush(%{ref: nil} = state) do
    state
  end

  # If there is an existing ref, that means we need to wait for
  # the IO device to inform us that it is done writing.
  def flush(state) do
    state
    |> wait_for_device()
    |> flush()
  end

  defmodule BadDeviceError do
    @moduledoc """
    Error raised when the device being sought is non-existent or otherwise
    cannot be found or used
    """

    defexception [:messagesage, :type, :path, :reason]

    def message(%{type: :user, reason: :not_registered}) do
      """
      A process with the name `:user` is not registered. Cannot log to a
      device that does not exist.
      """
    end

    def message(%{type: :file, path: path, reason: :enoent}) do
      """
      Attempted to open file for writing at the path

      #{path}
      
      but the file could not be opened or created.
      """
    end

    def message(%{type: :file, path: path, reason: :eacces}) do
      """
      Attempted to open file for writing at the path

      #{path}
      
      but the current filesystem permissions do not allow this
      """
    end

    def message(%{type: :file, path: path, reason: :eisdir}) do
      """
      Attempted to open file for writing at the path

      #{path}
      
      but the path specified is a directory according to the filesystem
      """
    end

    def message(%{type: :file, path: path, reason: :enospc}) do
      """
      Attempted to open file for writing at the path

      #{path}
      
      but the filesystem has indicated there is no space available to write
      """
    end

    def message(_) do
      """
      Failed to find the IO device to log to for unknown reasons. Please file
      a bug report at https://github.com/timberio/timber-elixir/issues
      """
    end
  end
end
