defmodule Timber.Contexts.RuntimeContext do
  @moduledoc ~S"""
  **DEPRECATED**

  This module is deprecated in favor of using `map`s. The next evolution of Timber (2.0)
  no long requires a strict schema and therefore simplifies how users set context:

      Timber.add_context(runtime: %{application: "my_app", file: "my_file.ex"})

  Please note that this context is added automatically as part of shipping log data.
  You should not have to do anything to obtain this context.
  """

  @type t :: %__MODULE__{
          application: String.t(),
          file: String.t(),
          function: String.t(),
          line: String.t(),
          module_name: String.t(),
          vm_pid: String.t()
        }

  @type m :: %{
          application: String.t(),
          file: String.t(),
          function: String.t(),
          line: String.t(),
          module_name: String.t(),
          vm_pid: String.t()
        }

  defstruct [:application, :file, :function, :line, :module_name, :vm_pid]

  defimpl Timber.Contextable do
    def to_context(context) do
      context = Map.from_struct(context)
      %{runtime: context}
    end
  end
end
