defmodule Timber.Events.ErrorEvent do
  @moduledoc """
  The `ErrorEvent` is used to track errors and exceptions.

  The defined structure of this data can be found in the log event JSON schema:
  https://github.com/timberio/log-event-json-schema

  Timber automatically tracks and structures errors and exceptions in your application. Giving
  you detailed stack traces, context, and error data.
  """

  @type stacktrace_entry :: {
    module,
    atom,
    arity,
    [file: IO.chardata, line: non_neg_integer] | []
  }

  @type backtrace_entry :: %{
    app_name: String.t | nil,
    function: String.t,
    file: String.t | nil,
    line: non_neg_integer | nil
  }

  @type t :: %__MODULE__{
    backtrace: [backtrace_entry] | [],
    name: String.t,
    message: String.t | nil,
    metadata_json: binary | nil,
    type: String.t | nil
  }

  @enforce_keys [:name]
  defstruct [:backtrace, :name, :type, :message, :metadata_json]

  @app_name_byte_limit 256
  @file_byte_limit 1_024
  @function_byte_limit 256
  @max_backtrace_size 20
  @message_byte_limit 8_192
  @metadata_json_byte_limit 8_192
  @name_byte_limit 256

  @doc """
  Convenience methods for building error events, taking care to normalize values
  and ensure they meet the validation requirements of the Timber API.
  """
  def new(name, message, opts \\ []) do
    name =
      name
      |> Timber.Utils.Logger.truncate_bytes(@name_byte_limit)
      |> to_string()

    message =
      message
      |> Timber.Utils.Logger.truncate_bytes(@message_byte_limit)
      |> to_string()

    backtrace =
      case Keyword.get(opts, :backtrace, nil) do
        nil -> nil
        backtrace -> Enum.slice(backtrace, 0..(@max_backtrace_size - 1))
      end

    metadata_json =
      case Keyword.get(opts, :metadata_json, nil) do
        nil ->
          nil

        metadata_json ->
          metadata_json
          |> Timber.Utils.Logger.truncate_bytes(@metadata_json_byte_limit)
          |> to_string()
      end

    struct!(
      __MODULE__,
      name: name,
      message: message,
      backtrace: backtrace,
      metadata_json: metadata_json
    )
  end

  @doc """
  Builds a new error event from an error / exception.
  """
  @spec from_exception(Exception.t) :: t
  def from_exception(%{__exception__: true, __struct__: module} = error) do
    message = Exception.message(error)
    module_name = Timber.Utils.Module.name(module)
    metadata_map =
      error
      |> Map.from_struct()
      |> Map.delete(:__exception__)
      |> Map.delete(:__struct__)
      |> Map.delete(:message)
    metadata_json =
      if metadata_map == nil || metadata_map == %{} do
        nil
      else
        case Timber.Utils.JSON.encode_to_iodata(metadata_map) do
          {:ok, json} -> IO.iodata_to_binary(json)
          {:error, _error} -> nil
        end
      end

    %__MODULE__{
      name: module_name,
      message: message,
      metadata_json: metadata_json
    }
  end

  @doc """
  Adds a stacktrace to an event, converting it if necessary
  """
  @spec add_backtrace(t, stacktrace_entry | backtrace_entry) :: t
  def add_backtrace(event, [trace | _] = backtrace) when is_map(trace) do
    backtrace = Enum.slice(backtrace, 0..(@max_backtrace_size - 1))
    %{event | backtrace: backtrace}
  end

  def add_backtrace(event, [stack | _rest] = stacktrace) when is_tuple(stack) do
    add_backtrace(event, stacktrace_to_backtrace(stacktrace))
  end

  def add_backtrace(event, []) do
    event
  end

  @doc """
  Builds an error from the given log message. This allows us to create Error events
  downstream in the logging flow. Because of the complicated nature around Elixir
  exception handling, this is a reliable catch-all to ensure all error are capture
  and processed properly.
  """
  @spec from_log_message(String.t) ::
    {:ok, t} |
    {:error, atom}
  def from_log_message(log_message) do
    lines =
      log_message
      |> String.split("\n")
      |> Enum.map(&({&1, String.trim(&1)}))

    case do_from_log_message({nil, "", []}, lines) do
      {:ok, {name, message, backtrace}} when is_binary(name) and length(backtrace) > 0 ->
        error = new(name, message, backtrace: backtrace)
        {:ok, error}

      _ ->
        {:error, :could_not_parse_message}
    end
  end

  defp stacktrace_to_backtrace(stacktrace) do
    # arity is an integer or list of arguments
    Enum.map(stacktrace, fn({module, function, arity, location}) ->
      arity = case arity do
        arity when is_list(arity) -> length(arity)
        _ -> arity
      end

      file = Keyword.get(location, :file)
             |> Kernel.to_string()
      line = Keyword.get(location, :line)

      %{
        function: Exception.format_mfa(module, function, arity),
        file: file,
        line: line
      }
    end)
  end

  # ** (exit) an exception was raised:
  defp do_from_log_message({nil, message, [] = backtrace}, [{_raw_line, ("** (exit) " <> _suffix)} | lines]) do
    do_from_log_message({nil, message, backtrace}, lines)
  end

  #    ** (RuntimeError) my message
  defp do_from_log_message({nil, _message, [] = backtrace}, [{_raw_line, ("** (" <> line_suffix)} | lines]) do
    # Using split since it is more performance with binary scanning
    case String.split(line_suffix, ")", parts: 2) do
      [name, message] ->
        do_from_log_message({name, message, backtrace}, lines)

      _ -> {:error, :malformed_error_message}
    end
  end

  # Ignore other leading messages
  defp do_from_log_message({nil, _message, _backtrace} = acc, [_line | lines]), do: do_from_log_message(acc, lines)

  #      (odin_client_api) web/controllers/page_controller.ex:5: Odin.ClientAPI.PageController.index/2
  defp do_from_log_message({name, message, backtrace}, [{_raw_line, ("(" <> line_suffix)} | lines]) when not is_nil(name) and not is_nil(message) do
    # Using split since it is more performance with binary scanning
    with [app_name, line_suffix] <- String.split(line_suffix, ") ", parts: 2),
         [file, line_suffix] <- String.split(line_suffix, ":", parts: 2),
         [line_number, function] <- String.split(line_suffix, ":", parts: 2)
    do
      app_name =
        app_name
        |> Timber.Utils.Logger.truncate_bytes(@app_name_byte_limit)
        |> to_string()

      function =
        function
        |> String.trim()
        |> Timber.Utils.Logger.truncate_bytes(@function_byte_limit)
        |> to_string()

      file =
        file
        |> String.trim()
        |> Timber.Utils.Logger.truncate_bytes(@file_byte_limit)
        |> to_string()

      if function != "" && file != "" do
        line = %{
          app_name: app_name,
          function: String.trim(function),
          file: String.trim(file),
          line: parse_line_number(line_number)
        }
        do_from_log_message({name, message, [line | backtrace]}, lines)
      else
        {:error, :malformed_stacktrace_line}
      end

    else
      _ ->
        {:error, :malformed_stacktrace_line}
    end
  end

  # Ignore lines we don't recognize.
  defp do_from_log_message(acc, [_line | lines]), do: do_from_log_message(acc, lines)

  # Finish the iteration, reversing the backtrace for performance reasons.
  defp do_from_log_message({name, message, backtrace}, []) do
    {:ok, {name, String.trim(message), Enum.reverse(backtrace)}}
  end

  defp parse_line_number(line_str) do
    case Integer.parse(line_str) do
      {line, _unit} -> line
      :error -> nil
    end
  end

  @doc """
  Message to be used when logging.
  """
  @spec message(t) :: IO.chardata
  def message(%__MODULE__{name: name, message: message}), do: [?(, name, ?), ?\s, message]
end
