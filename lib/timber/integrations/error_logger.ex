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
  exception will be displayed twice in the log. This module also consolidates many
  error reports into a single line that by default would be logged across multiple
  lines.

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

  @behaviour :gen_event

  alias Timber.Events.ErrorEvent

  @doc false
  def init(opts \\ []) do
    # As this is a :gen_event module, there is no built-in back-pressure mechanism.
    # To avoid holding too many messages, the process will keep up to a default of
    # 300 messages. This level is under the `:max_count` key in the state.
    # Once this level is reached, it will drop messages until it
    # is holding 75% of the maximum (225 by default). This level is under the
    # `:keep_count` key in the state. Once messages have been dropped,
    # it will process 10% of the maximum messages (the next 30 by default)
    # to avoid dropping too many consecutive messages before checking the message
    # count again. The number of messages to process during this is tracked under the
    # `:skip_count` key in the state.

    # The pid for the `Logger` process is also stored in state so messages can be
    # sent from this process to a pid instead of a named process. This is to avoid
    # crashing when sending messages to a named process.

    max_message_count = Keyword.get(opts, :max_message_count, 300)
    state = %{
      logger: Process.whereis(Logger),
      skip_count: 0,
      max_count: max_message_count,
      keep_count: trunc(max_message_count * 0.75),
    }

    {:ok, state}
  end

  @doc false
  # Ignores log events from other nodes
  def handle_event({_, gl, _}, state) when node(gl) != node() do
    {:ok, state}
  end

  def handle_event(event , state) do
    state = check_threshold(state)
    log_event(event, state)

    {:ok, state}
  end

  def get_metadata({_format, [_pid, {error, stacktrace}]}, :error) do
    case handle_error_info({error, stacktrace}) do
      {:ok, event} ->
        Timber.Event.to_metadata(event)
      {:error, _} ->
        []
    end
  end

  def get_metadata({_format, [_pid, _last_message, _state, {error, stacktrace}]}, :error) when is_list(stacktrace) do
    case handle_error_info({error, stacktrace}) do
      {:ok, event} ->
        Timber.Event.to_metadata(event)
      {:error, _} ->
        []
    end
  end

  def get_metadata({_format, [_pid, _last_message, _state, reason]}, :error) do
    case handle_error_info({reason, []}) do
      {:ok, event} ->
        Timber.Event.to_metadata(event)
      {:error, _} ->
        []
    end
  end

  def get_metadata({_format, [_, _, _, {error, stacktrace}]}, :error) do
    case handle_error_info({error, stacktrace}) do
      {:ok, event} ->
        Timber.Event.to_metadata(event)
      {:error, _} ->
        []
    end
  end

  def get_metadata({_format, [_, _, _, error]}, :error) do
    case handle_error_info({error, []}) do
      {:ok, event} ->
        Timber.Event.to_metadata(event)
      {:error, _} ->
        []
    end
  end

  def get_metadata({_format, [_pid, _message, _pid2, {error, stack}, _pid3, _stack2]}, :error) do
    case handle_error_info({error, stack}) do
      {:ok, event} ->
        Timber.Event.to_metadata(event)
      {:error, _} ->
        []
    end
  end

  def get_metadata({_format, [_pid, _pid2, _function, _args, {error, stacktrace}]}, :error) do
    case handle_error_info({error, stacktrace}) do
      {:ok, event} ->
        Timber.Event.to_metadata(event)
      {:error, _} ->
        []
    end
  end

  def get_metadata(_, _) do
    []
  end

  defp log_event({:error, gl, {pid, format, data}}, state),
    do: do_log_event(:error, :format, gl, pid, {format, data}, state)

  defp log_event({:error_report, gl, {pid, :std_error, format}}, state),
    do: do_log_event(:error, :report, gl, pid, {:std_error, format}, state)

    defp log_event({:warning_msg, gl, {pid, format, data}}, state),
    do: do_log_event(:warn, :format, gl, pid, {format, data}, state)

  defp log_event({:warning_report, gl, {pid, :std_warning, format}}, state),
    do: do_log_event(:warn, :report, gl, pid, {:std_warning, format}, state)

  defp log_event({:info_msg, gl, {pid, format, data}}, state),
    do: do_log_event(:info, :format, gl, pid, {format, data}, state)

  defp log_event({:info_report, gl, {pid, :std_info, format}}, state),
    do: do_log_event(:info, :report, gl, pid, {:std_info, format}, state)

  defp log_event(_, _state), do: :ok

  defp do_log_event(level, kind, gl, pid, data, state) do
    %{
      mode: mode,
      level: min_level,
      utc_log: utc_log?,
      truncate: truncate,
      translators: translators,
    } = Logger.Config.__data__()

    with true <- Logger.compare_levels(level, min_level) != :lt and mode != :discard,
         {:ok, message} <- translate(translators, min_level, level, kind, data, truncate) do

      meta = get_metadata(data, level)
             |> Keyword.put(:pid, pid)
      message = Logger.Utils.truncate(message, truncate)
      event = {Logger, message, Logger.Utils.timestamp(utc_log?), meta}
      :gen_event.notify(state.logger, {level, gl, event})
    end
  end

  def handle_info(_, state) do
    {:ok, state}
  end

  def handle_call(_, state) do
    {:reply, :ok, state}
  end

  defp handle_error_info({{%{__exception__: true} = error, stacktrace}, _stack}) when is_list(stacktrace) do
    {:ok, build_error_event(error, stacktrace, :error)}
  end

  defp handle_error_info({%{__exception__: true} = error, stacktrace}) when is_list(stacktrace) do
    {:ok, build_error_event(error, stacktrace, :error)}
  end

  defp handle_error_info({type, {reason, stacktrace}, _stack}) when is_list(stacktrace) do
    {:ok, build_error_event(reason, stacktrace, type)}
  end

  defp handle_error_info({{type, reason}, stacktrace}) when is_list(stacktrace) do
    {:ok, build_error_event(reason, stacktrace, type)}
  end

  defp handle_error_info({type, reason, stacktrace}) when is_list(stacktrace) do
    {:ok, build_error_event(reason, stacktrace, type)}
  end

  defp handle_error_info({error, stacktrace}) when is_list(stacktrace) do
    {:ok, build_error_event(error, stacktrace, :error)}
  end

  defp handle_error_info(_) do
    {:error, :no_info}
  end

  defp build_error_event(%{__exception__: true} = error, stacktrace, _type) do
    e = ErrorEvent.from_exception(error)
        |> ErrorEvent.add_backtrace(stacktrace)

    # %{e | type: to_string(type)}
    e
  end

  defp build_error_event(error, stacktrace, _type) do
    e = ErlangError.normalize(error, stacktrace)
        |> ErrorEvent.from_exception()
        |> ErrorEvent.add_backtrace(stacktrace)

    # %{e | type: to_string(type)}
    e
  end

  @spec handle_process_dictionary(any) :: map
  defp handle_process_dictionary([]) do
    %{}
  end

  defp handle_process_dictionary(dictionary) when is_list(dictionary) do
    with {:ok, {true, metadata}} <- Keyword.fetch(dictionary, :logger_metadata),
         {:ok, context} <- Keyword.fetch(metadata, :timber_context)
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

  defp check_threshold(%{skip_count: 0, keep_count: keep_count, max_count: max_count} = state) do
    current_count = message_count()

    if current_count >= max_count do
      drop_count = current_count - keep_count
      discard_messages(drop_count)

      message =
        "Timber.ErrorLogger has discarded #{drop_count} of #{current_count} messages in " <>
          "its inbox. The maximum number of messages is #{max_count}. " <>
          "The current number of messages is now #{keep_count}"

      %{utc_log: utc_log?} = Logger.Config.__data__()
      event = {Logger, message, Logger.Utils.timestamp(utc_log?), pid: self()}
      :gen_event.notify(state.logger, {:warn, Process.group_leader(), event})

      # Send 10% of the maximum messages before checking message count again
      %{state | skip_count: trunc(max_count * 0.1)}
    else
      state
    end
  end

  defp check_threshold(%{skip_count: skip_count} = state) do
    %{state | skip_count: skip_count - 1}
  end

  defp message_count() do
    {:message_queue_len, count} = Process.info(self(), :message_queue_len)
    count
  end

  defp discard_messages(0) do
    :ok
  end

  defp discard_messages(count) do
    receive do
      {:notify, _event} ->
        discard_messages(count - 1)
    after
      0 -> :ok
    end
  end

  defp translate([{mod, fun} | t], min_level, level, kind, data, truncate) do
    case apply(mod, fun, [min_level, level, kind, data]) do
      {:ok, chardata} -> {:ok, chardata}
      :skip -> :skip
      :none -> translate(t, min_level, level, kind, data, truncate)
    end
  end

  defp translate([], _min_level, _level, :format, {format, args}, truncate) do
    msg =
      format
      |> Logger.Utils.scan_inspect(args, truncate)
      |> :io_lib.build_text()

    {:ok, msg}
  end

  defp translate([], _min_level, _level, :report, {_type, data}, _truncate) do
    {:ok, Kernel.inspect(data)}
  end
end
