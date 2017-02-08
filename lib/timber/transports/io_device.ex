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

  ## Configuration Recommendations: Development vs. Production

  In a standard Elixir project, you will probably have different configuration files
  for your development and production setups. These configuration files typically
  take the form of `config/dev.exs` and `config/prod.exs` which override defaults set
  in `config/config.exs`.

  Timber's defaults are production ready, but the production settings also assume that
  you'll be viewing the logs through the Timber console, so they forego some niceties
  that help when developing locally. Therefore, to help with local development, we
  recommended this configuration for your `:dev` environment:

  ```
  # config/dev.exs

  config :timber, :io_device,
    colorize: true,
    format: :logfmt,
    print_timestamps: true
    print_log_level: true
  ```

  This will configure Timber to output logs in logfmt instead of JSON, print the log
  level and timestamps, and colorize the logs.

  ## Transport Configuration Options

  The following options are available when configuring the IODevice logger:

  #### `colorize`

  When `true`, the log level will be printed in a corresponding color using
  ANSI console control characters to help identify it.

  When `false`, the log level will be printed out as standard text.

  _Defaults to `true`._

  #### `escape_new_lines`

  When `true`, new lines characters are escaped as `\\n`.

  When `false`, new lines characters are left alone.

  This circumvents issues with output devices (like Heroku Logplex) that will tranform
  line breaks into multiple log lines.

  When the IODevice transport is initialized, it will check for the environment
  variable `HEROKU`. If the environment variable is present, this will be set to
  `true`. Otherwise, this defaults to `false`. Setting the value in your application
  configuration will always override the initialized setting..

  #### `format`

  Determines the output format to use. Even though the Timber service is designed
  to receive log metadata in JSON format, it's not the prettiest format to look at when
  you're developing locally. Therefore, we let you print the metadata in logfmt locally
  to make it easier on the eyes.

  Valid values:

    - `:json`
    - `:logfmt` (not supported in production)

  _Defaults to `:json`._

  #### `max_buffer_size`

  The maximum number of log entries that the log event buffer will hold until
  the transport switchs to synchronous mode. This value should be tuned to
  accomodate your system's IO capability versus the amount of logging you
  perform.

  _Defaults to `100`._

  #### `print_log_level`

  When `true`, the log level is printed in brackets as part of your log message.

  When `false`, the log level is not printed.

  Regardless of the setting used, the log level will be recorded as part of Timber's
  metadata. Setting this to `false` is recommended for production usage if you only
  use Timber for viewing logs.

  _Defaults to `false`._

  #### `print_metadata`

  The Timber metadata contains additional information about your log lines, but this
  can become unwieldy in local development scenarios.

  When `true`, the Timber metadata is printed out at the end of the log line (starting
  with the indicator "timber.io").

  When `false`, the Timber metadata is not printed.

  Note: This should _always_ be `true` in production.

  _Defaults to `true`._

  #### `print_timestamps`

  When `true`, the timestamp for the log will be output at the front
  of the statement.

  When `false`, the timestamp will be suppressed. This is only useful in situations
  where the log will be written to an evented IO service that automatically adds
  timestamps for incoming data, like Heroku Logplex.

  Regardless of the setting used, the timestamp will be recorded as part of Timber's
  metadata. Setting this to `false` is recommended for production usage if you only
  use Timber for viewing logs.

  _Defaults to `false`._
  """

  @behaviour Timber.Transport

  alias Timber.{LogEntry, LoggerBackend}
  alias __MODULE__.BadDeviceError

  @default_colorize true
  @default_max_buffer_size 100
  @default_escape_new_lines false
  @default_format :json
  @default_print_log_level false
  @default_print_metadata true
  @default_print_timestamps false
  @metadata_delimiter " @timber.io "

  @typep t :: %__MODULE__{
    ref: reference | nil,
    device: nil | IO.device,
    output: nil | IO.chardata,
    buffer_size: non_neg_integer,
    max_buffer_size: pos_integer,
    colorize: boolean,
    escape_new_lines: boolean,
    format: :json | :logfmt,
    print_log_level: boolean,
    print_metadata: boolean,
    print_timestamps: boolean,
    buffer: [] | [IO.chardata]
  }

  defstruct device: nil,
            ref: nil,
            output: nil,
            buffer_size: 0,
            colorize: @default_colorize,
            escape_new_lines: @default_escape_new_lines,
            format: @default_format,
            max_buffer_size: @default_max_buffer_size,
            print_log_level: @default_print_log_level,
            print_metadata: @default_print_metadata,
            print_timestamps: @default_print_timestamps,
            buffer: []

  @doc false
  @spec init() :: {:ok, t}
  def init() do
    init_config = get_init_config()
    filename = Keyword.get(init_config, :file, :no_file)

    with {:ok, device} <- get_device(filename),
         {:ok, state} <- configure(init_config, %__MODULE__{device: device}),
         do: {:ok, state}
  end

  # Gets the transport configuration by looking up the value in the Application
  # configuration
  @spec get_init_config() :: Keyword.t
  defp get_init_config() do
    heroku_env = System.get_env("HEROKU")
    heroku? = !is_nil(heroku_env)

    init_env = [escape_new_lines: heroku?]

    env = Application.get_env(:timber, :io_device, [])

    Keyword.merge(init_env, env)
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
  def configure(options, state) do
    colorize = Keyword.get(options, :colorize, @default_colorize)
    escape_new_lines = Keyword.get(options, :escape_new_lines, @default_escape_new_lines)
    format = Keyword.get(options, :format, @default_format)
    max_buffer_size = Keyword.get(options, :max_buffer_size, @default_max_buffer_size)
    print_log_level = Keyword.get(options, :print_log_level, @default_print_log_level)
    print_metadata = Keyword.get(options, :print_metadata, @default_print_metadata)
    print_timestamps = Keyword.get(options, :print_timestamps, @default_print_timestamps)

    new_state = %{ state |
      colorize: colorize,
      escape_new_lines: escape_new_lines,
      format: format,
      max_buffer_size: max_buffer_size,
      print_log_level: print_log_level,
      print_metadata: print_metadata,
      print_timestamps: print_timestamps
    }

    {:ok, new_state}
  end

  @doc false
  @spec write(LogEntry.t, t) :: {:ok, t}
  def write(%LogEntry{dt: timestamp, level: level, message: message} = log_entry, state) do
    device = state.device
    ref = state.ref
    buffer_size = state.buffer_size
    max_buffer_size = state.max_buffer_size

    level_b = colorize_log_level(level, state.colorize)

    metadata =
      if state.print_metadata do
        log_entry
        |> LogEntry.to_string!(state.format, only: [:dt, :level, :event, :context])
        |> wrap_metadata()
      else
        []
      end

    line_output =
      [message, metadata]
      |> add_log_level(level_b, state.print_log_level)
      |> add_timestamp(timestamp, state.print_timestamps)
      |> escape_new_lines(state.escape_new_lines)

    # Prevents the final new line from being escaped
    output = [line_output, ?\n]

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

  @spec wrap_metadata(IO.chardata) :: IO.chardata
  defp wrap_metadata(metadata) do
    [@metadata_delimiter, metadata]
  end

  @spec add_timestamp(IO.chardata, IO.chardata, boolean) :: IO.chardata
  defp add_timestamp(message, _, false), do: message
  defp add_timestamp(message, timestamp, true) do
    [timestamp, " " |  message]
  end

  @spec add_log_level(IO.chardata, IO.charadata, boolean) :: IO.chardata
  defp add_log_level(message, _, false), do: message
  defp add_log_level(message, log_level, true) do
    ["[", log_level, "] " | message ]
  end

  @spec colorize_log_level(LoggerBackend.level, boolean) :: IO.chardata
  defp colorize_log_level(level_a, false), do: Atom.to_string(level_a)
  defp colorize_log_level(level_a, true) do
    color = log_level_color(level_a)
    level_b = Atom.to_string(level_a)

    [color, level_b]
    |> IO.ANSI.format(true)
  end

  @spec log_level_color(LoggerBackend.level) :: atom
  defp log_level_color(:debug), do: :cyan
  defp log_level_color(:warn), do: :yellow
  defp log_level_color(:error), do: :red
  defp log_level_color(_), do: :normal

  @spec escape_new_lines(IO.chardata, boolean) :: IO.chardata
  defp escape_new_lines(msg, false), do: msg
  defp escape_new_lines(msg, true) do
    to_string(msg)
    |> String.replace(<< ?\n :: utf8 >>, << ?\\ :: utf8, ?n :: utf8 >>)
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
