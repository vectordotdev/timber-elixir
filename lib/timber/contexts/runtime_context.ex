defmodule Timber.Contexts.RuntimeContext do
  @moduledoc """
  The Runtime context tracks information about the current runtime, such as the module, file,
  function, and line number that called the log line.
  """

  @type t :: %__MODULE__{
    application: String.t,
    file: String.t,
    function: String.t,
    line: String.t,
    module_name: String.t,
    vm_pid: String.t
  }

  @type m :: %{
    application: String.t,
    file: String.t,
    function: String.t,
    line: String.t,
    module_name: String.t,
    vm_pid: String.t
  }

  defstruct [:application, :file, :function, :line, :module_name, :vm_pid]
end
