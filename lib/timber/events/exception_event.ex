defmodule Timber.Events.ExceptionEvent do
  @moduledoc """
  The exception event is used to track exceptions.

  Timber can automatically keep track of errors reported by the VM by hooking
  into the SASL reporting system to collect exception information, so it should
  be unnecessary to track exceptions manually. See `Timber.ErrorLogger` for
  more details.
  """
@type stacktrace_entry :: {
    module,
    atom,
    arity,
    [file: IO.chardata, line: non_neg_integer] | []
 }

  @type backtrace_entry :: %{
    function: String.t,
    file: String.t | nil,
    line: non_neg_integer | nil
  }

  @type t :: %__MODULE__{
    backtrace: [backtrace_entry] | [],
    name: String.t,
    message: String.t
  }

  defstruct [:backtrace, :name, :message]

  @spec new(atom | Exception.t, [stacktrace_entry] | []) :: t
  def new(error, stacktrace) do
    {name, message} = transform_error(error)
    backtrace = Enum.map(stacktrace, &transform_stacktrace/1)
    %__MODULE__{
      name: name,
      message: message,
      backtrace: backtrace
    }
  end

  @spec message(t) :: IO.chardata
  def message(%__MODULE__{message: message}),
    do: message

  defp transform_error(error) when is_atom(error) do
    name = inspect(error)
    {name, name}
  end

  defp transform_error(%{__exception__: true, __struct__: module} = error) do
    name = module_name(module)
    msg = Exception.message(error)
    {name, msg}
  end

  defp transform_stacktrace({module, function_name, arity, fileinfo}) do
    module_name = module_name(module)

    function_name = Atom.to_string(function_name)

    function = to_string([module_name, ?., function_name, ?/, to_string(arity)])

    backtrace_entry = %{
      function: function
    }

    case file_information(fileinfo) do
      {filename, lineno} ->
        backtrace_entry
        |> Map.put(:file, filename)
        |> Map.put(:line, lineno)
      _ ->
        backtrace_entry
    end
  end

  defp file_information([]) do
    :no_file
  end

  defp file_information(fileinfo) do
    filename = Keyword.get(fileinfo, :file)
    lineno = Keyword.get(fileinfo, :line)

    if filename && lineno do
      {to_string(filename), to_string(lineno)}
    else
      :bad_descriptor
    end
  end

  defp module_name(module) do
    module
    |> List.wrap()
    |> Module.concat()
    |> Atom.to_string()
  end
end
