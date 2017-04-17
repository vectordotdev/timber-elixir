defmodule Timber.LoggerBackends.HTTP do
  @moduledoc """
  Provides a logger backend that dispatches logs via HTTP

  The HTTP backend buffers and delivers log messages over HTTP to the Timber API.
  It uses batching and msgpack to deliver logs with high-throughput and little overhead.

  Note: We use this transport strategy internally at Timber for our log ingestion pipeline;
  generating ~250 logs per second with virtually no change in performance. For the curious,
  we log metrics, and this is how we are able to optimize our pipeline.

  Messages are always written to the buffer first. The buffer is only drained when it reaches
  its maximum allowed size or a specified amount of time has elapsed. This balances output with
  batching so that logs are sent even when the application doesn't produce enough logs to fill
  the buffer.

  The maximum allowed size of the buffer can be controlled with the `:max_buffer_size` configuration
  value.

  All outgoing requests are made asynchronously. If a second request is made while the
  previous (first) request is still being processed, then the transport will enter
  synchronous mode, waiting for a response before proceeding with the request.
  Synchronous mode will cause any logging calls to block until the request completes.

  ## Configuration

  ### Custom HTTP client

  The HTTP backend can use any HTTP client, so long as it supports asynchronous requests.
  Suport for `:hackney` is built into the library and is the default client, supported via
  `Timber.Transports.HTTP.HackneyClient`. You can define your own custom HTTP client by adhering
  to the `Timber.Transports.HTTP.Client` behaviour. Afterwards, you must specify your client
  in the configuration:

  ```
  config :timber, :http_client, MyHTTPClient
  ```
  """
  use GenEvent

  alias Timber.LogEntry
  alias Timber.Config
  alias __MODULE__.{NoHTTPClientError, NoTimberAPIKeyError, TimberAPIKeyInvalid}

  require Logger

  @typedoc """
  A representation of stateful data for this module

  ### min_level

  The minimum level to be logged. The Elixir `Logger` module typically
  handle filtering the log level, however this is a stop-gap for direct
  testing as well as any custom levels.
  """
  @type t :: %__MODULE__{
    min_level: level | nil,
    api_key: String.t,
    buffer_size: non_neg_integer,
    buffer: buffer,
    flush_interval: non_neg_integer,
    max_buffer_size: pos_integer,
    ref: reference
  }

  @type buffer :: [] | [IO.chardata]


  @typedoc """
  The level of a log event is described as an atom
  """
  @type level :: Logger.level # Reference to Elixir.Logger package

  @typedoc """
  The message for a log event is given as IO.chardata. It is important _not_
  to assume the message will be a `t:String.t/0`
  """
  @type message :: IO.chardata
  @type timestamp :: {date, time}
  @type date :: {year, month, day}

  @type year :: pos_integer
  @type month :: 1..12
  @type day :: 1..31

  @typedoc """
  Time is represented both to the millisecond and to the microsecond with precision.
  """
  @type time :: {hour, minute, second, millisecond} | {hour, minute, second, {microsecond, precision}}
  @type hour :: 0..23
  @type minute :: 0..59
  @type second :: 0..59
  @type millisecond :: 0..999
  @type microsecond :: 0..999999
  @typedoc """
  The precision of the microsecond represents the precision with which the fractional seconds are kept.

  See `t:Calendar.microsecond/0` for more information.
  """
  @type precision :: 0..6

  @content_type "application/msgpack"
  @default_max_buffer_size 5000 # 5000 log line should be well below 5mb
  @default_flush_interval 1000
  @frames_url "https://logs.timber.io/frames"

  defstruct min_level: nil,
            api_key: nil,
            buffer_size: 0,
            buffer: [],
            flush_interval: @default_flush_interval,
            http_client: nil,
            max_buffer_size: @default_max_buffer_size,
            ref: nil

  @doc false
  # Initializes the GenEvent system for this module. This
  # will be called by the Elixir `Logger` module when it
  # to add Timber as a logger backend.
  @spec init(__MODULE__, Keyword.t) :: {:ok, t}
  def init(__MODULE__, options \\ []) do
    with {:ok, conf_state} <- configure(options, %__MODULE__{}),
         {:ok, state} <- outlet(conf_state)
    do
      {:ok, state}
    end
  end

  # handle_call/2
  @doc false
  #
  # Note that the handle_call/2 defined here has a different return
  # structure than the one used in GenServers. This return structure
  # is particular to GenEvent modules. See the GenEvent documentation
  # for the handle_call/2 callback for more information.
  @spec handle_call({:configure, Keyword.t}, t) :: {:ok, :ok, t}
  def handle_call({:configure, options}, state) do
    {:ok, new_state} = configure(options, state)
    {:ok, :ok, new_state}
  end

  # handle_event/2
  @doc false
  # New logs and flush events are sent through event messages which
  # are processed through this function. It is similar in structure
  # to other handle_* type calls
  @spec handle_event({level, pid, {Logger, IO.chardata, timestamp, Keyword.t}} | any, t) :: {:ok, t}
  # Ignores log events from other nodes
  def handle_event({_level, gl, _event}, state) when node(gl) != node() do
    {:ok, state}
  end

  # Captures the event and outputs it (if appropriate) and buffers
  # the output (if appropriate)
  def handle_event({event_level, _gl, {Logger, msg, ts, md}}, state) do
    if event_level_adequate?(event_level, state.min_level) do
      output_event(ts, event_level, msg, md, state)
    else
      {:ok, state}
    end
  end

  # Informs the transport to flush any buffer it may have
  def handle_event(:flush, state) do
    {:ok, flush(state)}
  end

  # Ignores unhandled events
  def handle_event(_, state) do
    {:ok, state}
  end

  # handle_info/2
  @doc false
  # Receives reports from monitored processes and forwards them to
  # the transport. The transport _must_ implement at least
  # `handle_info/2` that returns `{:ok, state}`
  #
  # Handle the outlet step, this recursively calls through process messaging via
  # `Process.send_after/3`. This is how the flush interval is maintained.
  @spec handle_info(any, t) :: {:ok, t}
  def handle_info(:outlet, state) do
    {:ok, new_state} =
      state
      |> issue_request()
      |> outlet()
    {:ok, new_state}
  end

  # Do nothing for everything else.
  def handle_info(_, state) do
    {:ok, state}
  end

  # Called both during initialization of the event handler and when the
  # `{:config, _}` message is sent with configuration updates. Configuration
  # is modified by changing the state.
  @spec configure(Keyword.t, t) :: t
  defp configure(options, state) do
    api_key = Keyword.get(options, :api_key, Timber.Config.api_key())
    flush_interval = Keyword.get(options, :flush_interval, state.flush_interval)
    http_client = Keyword.get(options, :http_client, Timber.Config.http_client())
    max_buffer_size = Keyword.get(options, :max_buffer_size, state.max_buffer_size)
    min_level = Keyword.get(options, :min_level, state.min_level)

    changes = [
      api_key: api_key,
      flush_interval: flush_interval,
      http_client: http_client,
      max_buffer_size: max_buffer_size,
      min_level: min_level,
    ]

    new_state = struct!(state, changes)

    if new_state.api_key == nil do
      raise NoTimberAPIKeyError
    end

    if new_state.http_client == nil do
      raise NoHTTPClientError
    end

    new_state.http_client.start()
    run_http_preflight_check!(new_state.http_client, new_state.api_key)

    {:ok, new_state}
  end

  # Outputs the event to the transport, first converting it to a LogEvent
  @spec output_event(timestamp, level, IO.chardata, Keyword.t, t) :: t
  defp output_event(ts, level, message, metadata, state) do
    log_entry = LogEntry.new(ts, level, message, metadata)

    state = write_buffer(log_entry, state)

    if buffer_full?(state) do
      # The buffer is full, flush immediately.
      {:ok, flush(state)}
    else
      {:ok, state}
    end
  end

  @spec flush(t) :: t
  defp flush(state) do
    state
    |> issue_request()
    |> wait_on_request()
  end

  # Writes a log entry into the buffer
  @spec write_buffer(LogEntry.t, t) :: t
  defp write_buffer(log_entry, %{buffer: buffer, buffer_size: buffer_size} = state) do
    %{state | buffer: [log_entry | buffer], buffer_size: buffer_size + 1}
  end

  # The outlet recursively calls itself through process messaging via `Process.send_after/3`.
  # This allows us to clear the buffer on an interval ensuring messages are delivered, at most,
  # by the specified interval length.
  @spec outlet(t) :: {:ok, t}
  defp outlet(%{flush_interval: flush_interval} = state) do
    Timber.debug fn -> "Checking for logs to send, buffer size is #{state.buffer_size}" end
    Process.send_after(self(), :outlet, flush_interval)
    {:ok, state}
  end

  # Waits for the async request to complete
  @spec wait_on_request(t) :: t
  defp wait_on_request(%{ref: nil} = state) do
    state
  end

  defp wait_on_request(%{http_client: nil}) do
    raise NoHTTPClientError
  end

  defp wait_on_request(%{http_client: http_client, ref: ref}) do
    http_client.wait_on_request(ref)
  end

  # Delivers the buffer contents to Timber asynchronously using the provided HTTP client.
  # Asynchronous requests are required so that we do not block the caller and provide
  # back pressure needlessly.
  @spec issue_request(t) :: t
  defp issue_request(%{buffer: []} = state) do
    state
  end

  defp issue_request(%{api_key: nil}) do
    raise NoTimberAPIKeyError
  end

  defp issue_request(%{http_client: nil}) do
    raise NoHTTPClientError
  end

  defp issue_request(%{api_key: api_key, buffer: buffer, buffer_size: buffer_size,
    http_client: http_client} = state)
  do
    body = buffer_to_msg_pack(buffer)
    auth_token = Base.encode64(api_key)
    vsn = Application.spec(:timber, :vsn)
    user_agent = "Timber Elixir/#{vsn} (HTTP)"

    headers =
      %{
        "Authorization" => "Basic #{auth_token}",
        "Content-Type" => @content_type,
        "User-Agent" => user_agent
      }

    url = Config.http_url() || @frames_url

    case http_client.async_request(:post, url, headers, body) do
      {:ok, ref} ->
        Timber.debug fn -> "Issued HTTP request with reference #{inspect(ref)}" end

        new_buffer = clear_buffer(state)
        %{ new_buffer | ref: ref }

      {:error, reason} ->
        # If the buffer is full and we can't send the request, drop the buffer.
        if buffer_full?(state) do
          Timber.debug fn -> "Error issuing HTTP request #{inspect(reason)}. Buffer is full, dropping messages." end

          new_state = clear_buffer(state)

          Logger.error fn ->
            "Timber HTTP client dropped #{buffer_size} messages due to communication " <> \
              "errors with the Timber API"
          end

          new_state
        else
          Timber.debug fn ->
            "Error issuing HTTP request #{inspect(reason)}. Keeping buffer for retry next time."
          end
          # Ignore errors, keep the buffer, and allow the next attempt to retry.
          state
        end
    end
  end

  @spec buffer_full?(t) :: boolean
  defp buffer_full?(state) do
    state.buffer_size >= state.max_buffer_size
  end

  @spec clear_buffer(t) :: t
  defp clear_buffer(state) do
    %{ state | buffer: [], buffer_size: 0 }
  end

  # Encodes the buffer into msgpack
  @spec buffer_to_msg_pack(buffer) :: IO.chardata
  defp buffer_to_msg_pack(buffer) do
    buffer
    |> Enum.reverse()
    |> Enum.map(&LogEntry.to_map!/1)
    |> Enum.map(&prepare_for_msgpax/1)
    |> Msgpax.pack!()
  end

  # Normalizes the LogEntry.message into a string if it is not.
  @spec prepare_for_msgpax(LogEntry.t) :: LogEntry.t
  defp prepare_for_msgpax(%{message: nil} = log_entry), do: log_entry

  defp prepare_for_msgpax(log_entry_map) do
    Map.put(log_entry_map, :message, IO.chardata_to_string(log_entry_map.message))
  end

  # Checks whether the log event level meets or exceeds the
  # desired logging level. In the case no desired level is
  # configured, all levels pass
  @spec event_level_adequate?(level, level | nil) :: boolean
  defp event_level_adequate?(_lvl, nil) do
    true
  end

  defp event_level_adequate?(lvl, min) do
    Logger.compare_levels(lvl, min) != :lt
  end

  defp run_http_preflight_check!(http_client, api_key) do
    auth_token = Base.encode64(api_key)
    preflight_url = Config.preflight_url()

    headers = %{
      "Authorization" => "Basic #{auth_token}"
    }

    case http_client.request(:get, preflight_url, headers, "") do
      {:ok, status, _, _} when status in 200..299 ->
        :ok
      {:ok, status, _, _} ->
        raise TimberAPIKeyInvalid, api_key: api_key, status: status
      _ ->
        raise TimberAPIKeyInvalid, api_key: api_key
    end
  end

  #
  # Errors
  #

  defmodule NoHTTPClientError do
    defexception message: \
      """
      An HTTP client could not be found. Timber allows you to choose your HTTP
      client, but comes with a default :hackney click. Please use this via:

        config :timber, http_client: Timber.Transports.HTTP.HackneyClient
      """
  end

  defmodule NoTimberAPIKeyError do
    defexception message: \
      """
      We couldn't not locate your Timber API key. If you specified it
      as an environment variable, please ensure that this variable was
      added to your environment. Otherwise, please ensure that the
      api_key is specified during configuration:

        config :timber, api_key: "my_timber_api_key"

      You can location your API key in the Timber console by creating or
      editing your app: https://app.timber.io
      """
  end

  defmodule TimberAPIKeyInvalid do
    defexception [:message]

    def exception(opts) do
      api_key = Keyword.get(opts, :api_key)
      status = Keyword.get(opts, :status)

      message =
        """
        The Timber service does not recognize your API key. Please check
        that you have specified your key correctly.

          config :timber, api_key: "my_timber_api_key"

        You can locate your API key in the Timber console by creating or
        editing your app: https://app.timber.io

        Debug info:
        API key: #{inspect(api_key)}
        Status from the Timber API: #{inspect(status)}
        """

      %__MODULE__{message: message}
    end
  end
end
