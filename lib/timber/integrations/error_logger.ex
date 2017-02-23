defmodule Timber.Integrations.ErrorLogger do
  @moduledoc """
  Handles error reports from the `:error_logger` application.

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

  def handle_event({:error_report, _gl, {_pid, :crash_report, [error_report | _neighbors]}}, state) do
    error_info = Keyword.get(error_report, :error_info)

    case handle_error_info(error_info) do
      {:ok, event} ->
        context =
          error_report
          |> Keyword.get(:dictionary)
          |> handle_process_dictionary()

        message = ExceptionEvent.message(event)
        metadata =
          event
          |> Timber.Utils.Logger.event_to_metadata()
          |> Keyword.put(:timber_context, context)

        Logger.error(message, metadata)

      {:error, _} ->
        # do nothing
        :ok
    end

    {:ok, state}
  end

  def handle_event({:error, _gl, {_process, _msg_fmt, [_pid, {error, stacktrace}]}}, state) do
    event = ExceptionEvent.new(error, stacktrace)

    message = ExceptionEvent.message(event)
    metadata = Timber.Utils.Logger.event_to_metadata(event)

    Logger.error(message, metadata)

    {:ok, state}
  end

  def handle_event({:error, _gl, {_process, _msg_fmt, [_source, _protocol, _pid, {{error, stacktrace}, _other}]}}, state) do
    event = ExceptionEvent.new(error, stacktrace)

    message = ExceptionEvent.message(event)
    metadata = Timber.Utils.Logger.event_to_metadata(event)

    Logger.error(message, metadata)

    {:ok, state}
  end

  def handle_event(event, state) do
    Logger.error(inspect(event))
    {:ok, state}
  end

  defp handle_error_info({_type, error, stacktrace}) when is_list(stacktrace) do
    e = ExceptionEvent.new(error, stacktrace)
    {:ok, e}
  end

  defp handle_error_info({_type, {error, stacktrace}, _stack}) when is_list(stacktrace) do
    e = ExceptionEvent.new(error, stacktrace)
    {:ok, e}
  end

  defp handle_error_info(_) do
    {:error, :no_info}
  end

  @spec handle_process_dictionary(any) :: map
  defp handle_process_dictionary([]) do
    %{}
  end

  defp handle_process_dictionary(dictionary) when is_list(dictionary) do
    with {:ok, {true, metadata}} <- Keyword.get(dictionary, :logger_metadata),
         {:ok, context} <- Keyword.get(metadata, :timber_context)
    do
      context
    else
      _ ->
        %{}
    end
  end

  defp handle_process_dictionary(_) do
    %{}
  end
end
