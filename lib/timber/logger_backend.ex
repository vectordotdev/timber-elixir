defmodule Timber.LoggerBackend do
  @moduledoc """
  The LoggerBackend module is at the heart of Timber's integration. It specifies
  a backend that can be used with the standard `Logger` application distributed
  with Elixir.

  This module integrates with the transport mechanism you specify, and
  is responsible for receiving log events, determining whether the event is
  appropriate to output, and compiling the context data. Individual transports
  are responsible for maintaining buffers and whether the output should be
  asynchronous or synchronous.
  """
  use GenEvent

  alias Timber.LogEntry
  alias Timber.Transport

  @typedoc """
  A representation of stateful data for this module

  ### min_level

  The minimum level to be logged. The Elixir `Logger` module typically
  handle filtering the log level, however this is a stop-gap for direct
  testing as well as any custom levels.

  ### transport

  The transport module as an atom. This will be fetched at startup from
  the configuration.

  ### transport_state

  The transport state. This is initialized by calling `init/1` on the
  transport with transport configuration data from the application
  config.
  """
  @type t :: %__MODULE__{
    transport: module,
    min_level: level | nil,
    transport_state: Transport.state
  }

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

  defstruct transport: nil,
            min_level: nil,
            transport_state: nil

  @doc false
  # Initializes the GenEvent system for this module. This
  # will be called by the Elixir `Logger` module when it
  # to add Timber as a logger backend.
  @spec init(LoggerBackend) :: {:ok, t}
  def init(__MODULE__) do
    transport = Timber.Config.transport()

    case transport.init() do
      {:ok, transport_state} ->
        state = %__MODULE__{
          transport: transport,
          transport_state: transport_state
        }

        {:ok, state}
      {:error, error} -> {:error, error}
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
    new_state = configure(options, state)
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
    %{transport: transport, transport_state: transport_state} = state

    case transport.flush(transport_state) do
      {:ok, new_transport_state} ->
        new_state = %__MODULE__{state | transport_state: new_transport_state}
        {:ok, new_state}
      val -> val
    end
  end

  # Ignores unhandled events
  def handle_event(_, state) do
    {:ok, state}
  end

  # handle_info/1
  @doc false
  # Receives reports from monitored processes and forwards them to
  # the transport. The transport _must_ implement at least
  # `handle_info/2` that returns `{:ok, state}`
  @spec handle_info(any, t) :: {:ok, t}
  def handle_info(info, state) do
    %{transport: transport, transport_state: transport_state} = state

    case transport.handle_info(info, transport_state) do
      {:ok, new_transport_state} ->
        new_state = %__MODULE__{state | transport_state: new_transport_state}
        {:ok, new_state}
      val -> val
    end
  end

  # Called both during initialization of the event handler and when the
  # `{:config, _}` message is sent with configuration updates. Configuration
  # is modified by changing the state.
  @spec configure(Keyword.t, t) :: t
  defp configure(options, state) do
    {:ok, new_transport_state} = state.transport.configure(options, state.transport_state)
    level = Keyword.get(options, :level)

    %__MODULE__{state | transport_state: new_transport_state, min_level: level}
  end

  # Outputs the event to the transport, first converting it to a LogEvent
  @spec output_event(timestamp, level, IO.chardata, Keyword.t, t) :: t
  defp output_event(ts, level, message, metadata, state) do
    %{transport: transport, transport_state: transport_state} = state

    log_entry = LogEntry.new(ts, level, message, metadata)

    case transport.write(log_entry, transport_state) do
      {:ok, new_transport_state} ->
        new_state = %__MODULE__{state | transport_state: new_transport_state}
        {:ok, new_state}
      val -> val
    end
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
end
