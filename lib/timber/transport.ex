defmodule Timber.Transport do
  @moduledoc """
  A Transport specifies the way in which `Timber.Logger` should actually output
  log events.

  While the `Timber.Logger` module will handle receiving and processing log events,
  the process of actually outputting them is left to the trasnport. The transport
  is also responsible for managing any necessary buffers and switching between
  syncrhonous and asynchronous output.
  """

  alias Timber.LogEntry

  @typedoc """
  The transport state can be used to keep track of stateful data for operations,
  such as buffers and process IDs. It will always be passed as the final parameter
  to any expected callback and is expected to be returned by the function.
  """
  @type state :: any

  @doc """
  Flushes pending messages from any buffer

  If your transport implements a buffer, this call should essentially be synchronous,
  blocking until all messages in the buffer have been sent and confirmed output.
  """
  @callback flush(state) :: state

  @doc """
  Initializes the transport

  The transport is expected to start any necessary processes at this point. References
  to other processes should be kept in the state which is then returned.
  """
  @callback init() :: {:ok, state} | no_return

  @doc """
  Writes a log message to the transport

  The log entry to write will be sent along with the state. Writing the log entry
  is not expected to be immediate, but this function is expected to return quickly.
  If the transport uses a buffer, that buffer should be maintained in the state which
  is then returned.
  """
  @callback write(LogEntry.t, state) :: {:ok, state} | no_return

  @doc """
  Handles `handle_info` process messaging forwarded from `Timber.Logger`

  It is expected that your transport at least return `{:ok, state}` for
  any given `info`.
  """
  @callback handle_info(info :: tuple, state) :: {:ok, state} | no_return

  @doc """
  Passes configuration changes to the transport

  The transport is expected to store any configuration on the state it
  passes back.
  """
  @callback configure(options :: Keyword.t, state) :: {:ok, state} | {:error, Exception.t}
end
