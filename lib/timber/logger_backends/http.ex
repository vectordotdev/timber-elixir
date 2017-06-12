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
  """
  use GenEvent

  alias Timber.LogEntry
  alias Timber.Config
  alias __MODULE__.TimberAPIKeyInvalid

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

  # Despite there being an `http_client` field, this is only for testing; the HTTP client is
  # not actually configurable since it's impossible to support clients when we do not understand
  # the response messages in advance
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

  # Handles responses for asynchronous requests from Hackney for the last request made;
  # note that any other requests will fail the ref=ref pattern match and fall to the next
  # handle_info/2 definition
  def handle_info(msg = {:hackney_response, ref, _}, state = %{ref: ref}) do
    handle_hackney_response(msg, state)
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
    http_client = Keyword.get(options, :http_client, Timber.HTTPClients.Hackney)
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
      Timber.debug fn ->
        "The Timber API key is nil! Please check the documentation for how to specify an API key " <>
          "in your configuration file."
      end
    else
      Timber.debug fn -> "The Timber API key is present." end
    end

    new_state.http_client.start()

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

  @spec wait_on_request(t) :: t
  # Blocks until the last asynchronous request is received
  #
  # The function first checks whether there is a reference to a previous request.
  # If there isn't, it returns immediately.
  #
  # If there is an existing request, the function enters a `receive` block to look
  # for responses from Hackney. If it cannot find a response after 5 seconds, it will
  # abandon the previous request. If it finds a response, it sends it to the
  # handle_hackney_response/2 function which modifies the state apropriately based on
  # the message. It then loops on the new state.
  #
  defp wait_on_request(%{ref: nil} = state) do
    state
  end

  defp wait_on_request(state = %{ref: ref}) do
    receive do
      {:hackney_response, ^ref, msg} ->
        {:ok, new_state} = handle_hackney_response({:hackney_response, ref, msg}, state)

        wait_on_request(new_state)
      after 5000 ->
        Timber.debug fn -> "HTTP request #{inspect(ref)} exceeded timeout; abandoning it." end

        new_state = %{ state | ref: nil }
        wait_on_request(new_state)
    end
  end

  # Delivers the buffer contents to Timber asynchronously using the provided HTTP client.
  # Asynchronous requests are required so that we do not block the caller and provide
  # back pressure needlessly.
  @spec issue_request(t) :: t
  defp issue_request(%{buffer: []} = state) do
    state
  end

  defp issue_request(%{api_key: nil} = state) do
    Timber.debug fn -> "Timber API key is nil! Logs cannot be delivered without an API key." end
    state
  end

  defp issue_request(%{api_key: api_key, buffer: buffer, http_client: http_client} = state) do
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
          Timber.debug fn ->
            "Error issuing asynchronous HTTP request #{inspect(reason)}. Buffer is full, " <>
              "dropping messages."
          end

          clear_buffer(state)
        else
          Timber.debug fn ->
            "Error issuing asynchronous HTTP request #{inspect(reason)}. Keeping buffer " <>
              "for retry next time."
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

  @spec handle_hackney_response({:hackney_response, reference, term}, t) :: {:ok, t}
  # Handles responses from Hackney asynchronous requests and modifies the state appropriately
  #
  # This function assumes that its caller has already matched the reference being given to
  # the one existing in the state
  defp handle_hackney_response({:hackney_response, ref, {:ok, 401, reason}}, state) do
    Timber.debug fn -> "HTTP request #{inspect(ref)} received response 401 #{reason}" end

    raise TimberAPIKeyInvalid, status: 401, api_key: state.api_key
  end

  defp handle_hackney_response({:hackney_response, ref, {:ok, 403, reason}}, state) do
    Timber.debug fn -> "HTTP request #{inspect(ref)} received response 403 #{reason}" end

    {:ok, state}
  end

  defp handle_hackney_response({:hackney_response, ref, {:ok, status, reason}}, state) do
    Timber.debug fn -> "HTTP request #{inspect(ref)} received response #{status} #{reason}" end

    {:ok, state}
  end

  defp handle_hackney_response({:hackney_response, ref, {:error, error}}, state) do
    # In the event of an error on Hackney's part, we simply clear the reference.
    Timber.debug fn -> "HTTP request #{inspect(ref)} received error #{inspect(error)}" end

    new_state = %{ state | ref: nil }
    {:ok, new_state}
  end

  defp handle_hackney_response({:hackney_response, ref, :done}, state) do
    Timber.debug fn -> "HTTP request #{inspect(ref)} done" end

    new_state = %{ state | ref: nil }
    {:ok, new_state}
  end

  defp handle_hackney_response({:hackney_response, _ref, _}, state) do
    {:ok, state}
  end

  #
  # Errors
  #

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
