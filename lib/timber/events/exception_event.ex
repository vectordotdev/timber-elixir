defmodule Timber.Events.ExceptionEvent do
  @moduledoc """
  The `ExceptionEvent` is used to track exceptions.

  Timber automatically tracks and structures exceptions in your application. Giving
  you detailed stack traces, context, and exception data.
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
    message: String.t,
  }

  @enforce_keys [:backtrace, :name, :message]
  defstruct [:backtrace, :name, :message]

  @app_name_limit 255
  @file_limit 1_000
  @function_limit 255
  @message_limit 10_000
  @name_limit 255

  @doc """
  Builds a new struct taking care to normalize data into a valid state. This should
  be used, where possible, instead of creating the struct directly.
  """
  @spec new(String.t) :: {:ok, t} | {:error, atom}
  def new(log_message) do
    lines =
      log_message
      |> String.split("\n")
      |> Enum.map(&({&1, String.trim(&1)}))

    case do_new({nil, "", []}, lines) do
      {:ok, {name, message, backtrace}} when is_binary(name) and length(backtrace) > 0 ->
        name =
          name
          |> Timber.Utils.Logger.truncate(@name_limit)
          |> to_string()

        message =
          message
          |> Timber.Utils.Logger.truncate(@message_limit)
          |> to_string()

        {:ok, %__MODULE__{name: name, message: message, backtrace: backtrace}}

      _ ->
        {:error, :could_not_parse_message}
    end
  end

  # ** (exit) an exception was raised:
  defp do_new({nil, message, [] = backtrace}, [{_raw_line, ("** (exit) " <> _suffix)} | lines]) do
    do_new({nil, message, backtrace}, lines)
  end

  #    ** (RuntimeError) my message
  defp do_new({nil, _message, [] = backtrace}, [{_raw_line, ("** (" <> line_suffix)} | lines]) do
    # Using split since it is more performance with binary scanning
    case String.split(line_suffix, ")", parts: 2) do
      [name, message] ->
        do_new({name, message, backtrace}, lines)

      _ -> {:error, :malformed_error_message}
    end
  end

  # Ignore other leading messages
  defp do_new({nil, _message, _backtrace} = acc, [_line | lines]), do: do_new(acc, lines)

  #      (odin_client_api) web/controllers/page_controller.ex:5: Odin.ClientAPI.PageController.index/2
  defp do_new({name, message, backtrace}, [{_raw_line, ("(" <> line_suffix)} | lines]) when not is_nil(name) and not is_nil(message) do
    # Using split since it is more performance with binary scanning
    with [app_name, line_suffix] <- String.split(line_suffix, ") ", parts: 2),
         [file, line_suffix] <- String.split(line_suffix, ":", parts: 2),
         [line_number, function] <- String.split(line_suffix, ":", parts: 2)
    do
      app_name =
        app_name
        |> Timber.Utils.Logger.truncate(@app_name_limit)
        |> to_string()

      function =
        function
        |> String.trim()
        |> Timber.Utils.Logger.truncate(@function_limit)
        |> to_string()

      file =
        file
        |> String.trim()
        |> Timber.Utils.Logger.truncate(@file_limit)
        |> to_string()

      if function != "" && file != "" do
        line = %{
          app_name: app_name,
          function: String.trim(function),
          file: String.trim(file),
          line: parse_line_number(line_number)
        }
        do_new({name, message, [line | backtrace]}, lines)
      else
        {:error, :malformed_stacktrace_line}
      end

    else
      _ ->
        {:error, :malformed_stacktrace_line}
    end
  end

  # Ignore lines we don't recognize.
  defp do_new(acc, [_line | lines]), do: do_new(acc, lines)

  # Finish the iteration, reversing the backtrace for performance reasons.
  defp do_new({name, message, backtrace}, []) do
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
