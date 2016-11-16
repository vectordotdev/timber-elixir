defmodule Timber.ErrorLogger do
  @moduledoc """
  Handles error reports from the `:error_logger` application

  Timber can automatically log the exceptions that occur in your
  application as exception events with all the necessary metadata
  by registering as an `:error_logger` handler. To activate Timber's
  error logging system, you just need to add a few configuration
  lines:

  ```
  # Enable Timber's error capturing system
  config :timber, :capture_errors, true

  # Disable Elixir's default error capturing system
  config :logger, :handle_otp_reports, false
  ```

  ## Elixir Logger's OTP Report Handler

  The `Logger` application (which is distributed with Elixir) has an OTP report
  handler which logs errors and will activate it by default. However, the logs
  it writes only contain textual information without any metadata. Keeping this handler
  active will cause duplicate errors to be reported to the log, which is why
  we recommend disabling it using the following configuration option:

  ```
  config :logger, :handle_otp_reports, false
  ```
  
  However, the OTP report handler handles additional report types as well. If you
  find that you would like these reports to be logged, just be aware that every
  exception will be displayed twice in the log.

  Since the OTP report handler does not add the requisite metadata, Timber's console
  will not identify the errors it logs as exception events when you search.
  
  ## Elixir Logger's SASL Report Handler
  
  The Elixir `Logger` application also comes with a SASL (System Architecture Support Libraries)
  report handler. Timber does not currently handle these reports, so activating the
  standard handler will not cause duplicate logs.

  ## :error_logger Output
  
  When Timber's error capturing system is activated, it will also disable `:error_logger`'s `tty`
  output. In most cases, this is what you want, otherwise, otherwise it will print out reports
  to the `tty` in a plain text (and rather ugly) format.

  If you do not want the `tty` output to be disabled, you can keep it on using the following
  config:

  ```
  config :timber, :disable_kernel_error_tty, false
  ```
  """

  require Logger

  use GenEvent

  alias Timber.Events.ExceptionEvent

  @doc false
  def init(_) do
    {:ok, []}
  end

  @doc false
  def handle_call({:configure, _config}, state) do
    {:ok, :ok, state}
  end

  @doc false
  # Ignores log events from other nodes
  def handle_event({_report_type, gl, _report}, state) when node(gl) != node() do
    {:ok, state}
  end

  def handle_event({:error_report, _gl, _report}, state) do
    {:ok, state}
  end

  def handle_event({:error, _gl, {_process, _msg, [_pid, {error, stacktrace}]}}, state) do
    event = ExceptionEvent.new(error, stacktrace)
    Logger.error(event.description, timber_event: event)

    {:ok, state}
  end

  def handle_event(_event, state) do
    {:ok, state}
  end
end
