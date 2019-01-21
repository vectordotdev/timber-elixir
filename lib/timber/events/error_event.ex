defmodule Timber.Events.ErrorEvent do
  @moduledoc ~S"""
  **DEPRECATED**

  This module is deprecated in favor of using `map`s. The next evolution of Timber (2.0)
  no long requires a strict schema and therefore simplifies how users set context:

      Logger.info(fn ->
        message = Exception.message(error)
        event = %{error: %{name: error.__struct__, backtrace: backtrace}
        {message, event: event}
      end)

  Please note, errors can be automatically structured through the
  [`:timber_exceptions`](https://github.com/timberio/timber-elixir-exceptions) library.
  """

  @type stacktrace_entry :: {
          module,
          atom,
          arity,
          [file: IO.chardata(), line: non_neg_integer] | []
        }

  @type backtrace_entry :: %{
          app_name: String.t() | nil,
          function: String.t(),
          file: String.t() | nil,
          line: non_neg_integer | nil
        }

  @type t :: %__MODULE__{
          backtrace: [backtrace_entry] | nil,
          name: String.t(),
          message: String.t() | nil,
          metadata_json: binary | nil
        }

  @enforce_keys [:name]
  defstruct [:backtrace, :name, :message, :metadata_json]

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
  @spec from_exception(Exception.t()) :: t
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
      if map_size(metadata_map) == 0 do
        nil
      else
        case Jason.encode_to_iodata(metadata_map) do
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
  @spec add_backtrace(t, [stacktrace_entry] | [backtrace_entry]) :: t
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
  Message to be used when logging.
  """
  @spec message(t) :: IO.chardata()
  def message(%__MODULE__{name: name, message: message}),
    do: [?(, name, ?), ?\s, message]

  #
  # Util
  #

  @spec stacktrace_to_backtrace(list) :: [backtrace_entry]
  defp stacktrace_to_backtrace(stacktrace) do
    # arity is an integer or list of arguments
    Enum.map(stacktrace, fn {module, function, arity, location} ->
      arity =
        case arity do
          arity when is_list(arity) -> length(arity)
          _ -> arity
        end

      file =
        Keyword.get(location, :file)
        |> Kernel.to_string()

      line = Keyword.get(location, :line)

      %{
        function: Exception.format_mfa(module, function, arity),
        file: file,
        line: line
      }
    end)
  end

  #
  # Implementations
  #

  defimpl Timber.Eventable do
    def to_event(event) do
      event = Map.from_struct(event)
      %{error: event}
    end
  end
end
