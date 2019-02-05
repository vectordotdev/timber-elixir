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

  @behaviour :gen_event

  alias Timber.API
  alias Timber.Config
  alias Timber.Errors.InvalidAPIKeyError
  alias Timber.LogEntry

  require Logger

  #
  # Typespecs
  #

  @typedoc """
  A representation of stateful data for this module

  ### min_level

  The minimum level to be logged. The Elixir `Logger` module typically
  handle filtering the log level, however this is a stop-gap for direct
  testing as well as any custom levels.
  """
  @type t :: %__MODULE__{
          min_level: level | nil,
          api_key: String.t() | nil,
          buffer_size: non_neg_integer,
          buffer: buffer,
          flush_interval: non_neg_integer,
          max_buffer_size: pos_integer,
          ref: reference | nil
        }

  @typedoc """
  Internal buffer that is eventually flushed to the Timber.io service.
  """
  @type buffer :: [] | [LogEntry.t()]

  @typedoc """
  The level of a log event is described as an atom
  """
  # Reference to Elixir.Logger package
  @type level :: Logger.level()

  @typedoc """
  The message for a log event is given as IO.chardata. It is important _not_
  to assume the message will be a `t:String.t/0`
  """
  @type message :: IO.chardata()

  @typedoc """
  Timestamp forwarded from the Elixir `Logger` system.
  """
  @type timestamp :: {date, time}

  #
  # Timestamp parts
  #

  @type day :: 0..31
  @type date :: {year, month, day}
  @type hour :: 0..23
  @type microsecond :: 0..999_999
  @type millisecond :: 0..999
  @type minute :: 0..59
  @type month :: 1..12

  @typedoc """
  The precision of the microsecond represents the precision with which the fractional seconds are kept.

  See `t:Calendar.microsecond/0` for more information.
  """
  @type precision :: 0..6

  @type second :: 0..59

  @typedoc """
  Time is represented both to the millisecond and to the microsecond with precision.
  """
  @type time ::
          {hour, minute, second, millisecond} | {hour, minute, second, {microsecond, precision}}

  @type year :: pos_integer

  #
  # Module vars
  #

  @content_type "application/msgpack"
  @default_max_buffer_size 1000
  @default_flush_interval 1000
  @flush_timeout 5000

  #
  # Struct
  #

  # Despite there being an `http_client` field, this is only for testing; the HTTP client is
  # not actually configurable since it's impossible to support clients when we do not understand
  # the response messages in advance
  defstruct api_key: nil,
            buffer_size: 0,
            buffer: [],
            flush_interval: @default_flush_interval,
            max_buffer_size: @default_max_buffer_size,
            min_level: nil,
            ref: nil

  #
  # API
  #

  @doc false
  # Initializes a :gen_event handler from this module. This
  # will be called by the Elixir `Logger` module when it
  # to add Timber as a logger backend.
  @spec init(__MODULE__, Keyword.t()) :: {:ok, t}
  def init(__MODULE__, options \\ []) do
    with {:ok, conf_state} <- configure(options, %__MODULE__{}),
         {:ok, state} <- schedule_flush(conf_state) do
      {:ok, state}
    end
  end

  @doc false
  # handle_call/2
  #
  # Note that the handle_call/2 defined here has a different return
  # structure than the one used in GenServers. This return structure
  # is particular to :gen_event handlers. See the :gen_event documentation
  # for the handle_call/2 callback for more information.
  @spec handle_call({:configure, Keyword.t()}, t) :: {:ok, :ok, t}
  def handle_call({:configure, options}, state) do
    {:ok, new_state} = configure(options, state)
    {:ok, :ok, new_state}
  end

  @doc false
  # handle_event/2
  #
  # New logs and flush events are sent through event messages which
  # are processed through this function. It is similar in structure
  # to other handle_* type calls
  @spec handle_event({level, pid, {Logger, IO.chardata(), timestamp, Keyword.t()}} | any, t) ::
          {:ok, t}
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
    new_state = flush!(state)
    {:ok, new_state}
  end

  # Ignores unhandled events
  def handle_event(_, state) do
    {:ok, state}
  end

  @doc false
  # handle_info/2
  #
  # Receives reports from monitored processes and forwards them to
  # the transport. The transport _must_ implement at least
  # `handle_info/2` that returns `{:ok, state}`
  #
  # Handle the `:flush` step, this recursively calls through process messaging via
  # `Process.send_after/3`. This is how the flush interval is maintained.
  @spec handle_info(any, t) :: {:ok, t}
  def handle_info(:flush, state) do
    {:ok, new_state} =
      state
      |> try_issue_request()
      |> schedule_flush()

    {:ok, new_state}
  end

  # Do nothing if we aren't holding onto a request ref.
  def handle_info(_msg, %__MODULE__{ref: nil} = state) do
    {:ok, state}
  end

  # Delegate other messages to the HTTP client since the HTTP client is abstracted
  # and message handling should be delegated to the configured HTTP client.
  def handle_info(msg, state) do
    new_state =
      state.ref
      |> API.handle_async_response(msg)
      |> handle_async_response!(state)

    {:ok, new_state}
  end

  @doc false
  # No special handling for termination
  def terminate(_reason, _state) do
    :ok
  end

  @doc false
  # No special handling for code changes
  def code_change(_old, state, _extra) do
    {:ok, state}
  end

  #
  # Util
  #

  @spec buffer_full?(t) :: boolean
  defp buffer_full?(state) do
    state.buffer_size >= state.max_buffer_size
  end

  # Encodes the buffer into msgpack
  @spec buffer_to_msg_pack(buffer) ::
          {:ok, IO.chardata()}
          | {:error, Msgpax.PackError.t()}
          | {:error, Exception.t()}
  def buffer_to_msg_pack(buffer) do
    try do
      buffer
      |> Enum.reverse()
      |> Enum.map(&LogEntry.to_map!/1)
      |> Msgpax.pack()
      |> case do
        {:ok, binary} ->
          {:ok, binary}

        {:error, error} ->
          Timber.log(:error, fn ->
            "Log transmission failed. Msgpax encoding error: #{inspect(error)}"
          end)

          {:error, error}
      end
    catch
      :error, %Protocol.UndefinedError{protocol: Msgpax.Packer, value: value} = e ->
        Timber.log(:error, fn ->
          "Log transmission failed. Msgpax.Packer Protocol not implemented for: #{inspect(value)}"
        end)

        {:error, e}
    end
  end

  @spec clear_buffer(t) :: t
  defp clear_buffer(state) do
    %{state | buffer: [], buffer_size: 0}
  end

  # Called both during initialization of the event handler and when the
  # `{:config, _}` message is sent with configuration updates. Configuration
  # is modified by changing the state.
  @spec configure(Keyword.t(), t) :: {:ok, t}
  defp configure(options, state) do
    api_key = Keyword.get(options, :api_key, Config.api_key())
    flush_interval = Keyword.get(options, :flush_interval, state.flush_interval)
    max_buffer_size = Keyword.get(options, :max_buffer_size, state.max_buffer_size)
    min_level = Keyword.get(options, :min_level, state.min_level)

    changes = [
      api_key: api_key,
      flush_interval: flush_interval,
      max_buffer_size: max_buffer_size,
      min_level: min_level
    ]

    new_state = struct!(state, changes)

    if new_state.api_key == nil do
      Timber.log(:warn, fn ->
        "The Timber API key is nil! Please check the documentation for how to specify an API key " <>
          "in your configuration file."
      end)
    else
      Timber.log(:debug, fn -> "The Timber API key is present." end)
    end

    {:ok, new_state}
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

  # Flush data to Timber
  #
  # Flushing blocks until we have confirmed successful delivery or not, therefore,
  # flushing should only be used in situations where back pressure is desirable.
  @spec flush!(t) :: t
  defp flush!(state) do
    case try_issue_request(state) do
      # If we did not issue a request, return immediately.
      %__MODULE__{ref: nil} ->
        state

      # If we issued a request, wait for the response.
      state ->
        case API.wait_on_response(state.ref, @flush_timeout) do
          :timeout ->
            Timber.log(:error, fn ->
              "HTTP request #{inspect(state.ref)} exceeded timeout; abandoning it."
            end)

            %{state | ref: nil}

          response ->
            handle_async_response!(response, state)
        end
    end
  end

  # Outputs the event to the transport, first converting it to a LogEvent
  @spec output_event(timestamp, level, iodata(), Keyword.t(), t) :: {:ok, t}
  defp output_event(ts, level, message, metadata, state) do
    log_entry = LogEntry.new(ts, level, message, metadata)
    state = write_buffer(log_entry, state)

    if buffer_full?(state) do
      # The buffer is full, flush immediately.
      new_state = flush!(state)
      {:ok, new_state}
    else
      {:ok, state}
    end
  end

  # The outlet recursively calls itself through process messaging via `Process.send_after/3`.
  # This allows us to clear the buffer on an interval ensuring messages are delivered, at most,
  # by the specified interval length.
  @spec schedule_flush(t) :: {:ok, t}
  defp schedule_flush(state) do
    Timber.log(:debug, fn -> "Scheduling flush to occur in #{state.flush_interval}ms" end)
    Process.send_after(self(), :flush, state.flush_interval)
    {:ok, state}
  end

  # This method is public for testing purposes only
  @doc false
  def transmit_buffer(state, body) do
    Timber.log(:debug, fn ->
      byte_size = :erlang.iolist_size(body)
      "Sending buffer, byte size: #{byte_size}, size: #{state.buffer_size}"
    end)

    case API.send_logs(state.api_key, @content_type, body, async: true) do
      {:ok, ref} ->
        Timber.log(:debug, fn ->
          "Sent log buffer, HTTP request reference: #{inspect(ref)}"
        end)

        new_buffer = clear_buffer(state)
        %{new_buffer | ref: ref}

      {:error, reason} ->
        # If the buffer is full and we can't send the request, drop the buffer.
        if buffer_full?(state) do
          Timber.log(:error, fn ->
            "Error issuing asynchronous HTTP request #{inspect(reason)}. Buffer is full, " <>
              "dropping messages."
          end)

          clear_buffer(state)
        else
          Timber.log(:error, fn ->
            "Error issuing asynchronous HTTP request #{inspect(reason)}. Keeping buffer " <>
              "for retry next time."
          end)

          # Ignore errors, keep the buffer, and allow the next attempt to retry.
          state
        end
    end
  end

  # Delivers the buffer contents to Timber asynchronously using the provided HTTP client.
  # Asynchronous requests are required so that we do not block the caller and provide
  # back pressure needlessly.
  @spec try_issue_request(t) :: t
  defp try_issue_request(%__MODULE__{buffer: []} = state) do
    Timber.log(:debug, fn ->
      "Buffer is nil, skipping request"
    end)

    state
  end

  defp try_issue_request(%__MODULE__{api_key: nil} = state) do
    Timber.log(:error, fn ->
      "Timber API key is nil! Logs cannot be delivered without an API key."
    end)

    state
  end

  defp try_issue_request(%__MODULE__{ref: nil} = state) do
    case buffer_to_msg_pack(state.buffer) do
      {:ok, body} ->
        transmit_buffer(state, body)

      {:error, error} ->
        Timber.log(:error, fn ->
          "Buffer encoding failed: #{inspect(error)}"
        end)

        # Encoding failed and cannot send the request, so drop the buffer.
        clear_buffer(state)
    end
  end

  defp try_issue_request(state) do
    Timber.log(:info, fn ->
      "Can't issue request since we're still waiting on a response from #{inspect(state.ref)}"
    end)

    state
  end

  # Writes a log entry into the buffer
  @spec write_buffer(LogEntry.t(), t) :: t
  defp write_buffer(log_entry, %__MODULE__{buffer: buffer, buffer_size: buffer_size} = state) do
    %{state | buffer: [log_entry | buffer], buffer_size: buffer_size + 1}
  end

  @spec handle_async_response!(
          {:ok, HTTPClient.status(), HTTPClient.body()}
          | {:error, term}
          | :pass,
          t
        ) :: t
  # Handles responses from Hackney asynchronous requests and modifies the state appropriately
  #
  # This function assumes that its caller has already matched the reference being given to
  # the one existing in the state
  defp handle_async_response!({:ok, 401}, state) do
    Timber.log(:error, fn ->
      "HTTP request #{inspect(state.ref)} received a 401 response"
    end)

    raise InvalidAPIKeyError, status: 401, api_key: state.api_key
  end

  defp handle_async_response!({:ok, status}, state) do
    Timber.log(:debug, fn ->
      "HTTP request #{inspect(state.ref)} received a #{status} response"
    end)

    %{state | ref: nil}
  end

  defp handle_async_response!({:error, error}, state) do
    # In the event of an error on Hackney's part, we simply clear the reference.
    Timber.log(:error, fn ->
      "HTTP request #{inspect(state.ref)} received an error: #{inspect(error)}"
    end)

    %{state | ref: nil}
  end

  defp handle_async_response!(:pass, state) do
    Timber.log(:debug, fn ->
      "HTTP request #{inspect(state.ref)} received an unknown response, passing..."
    end)

    state
  end
end
