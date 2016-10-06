defmodule Timber.Contexts.ExceptionContext do
  @moduledoc """
  The exception context is used to track exceptions.

  To manually add an exception context to the stack, you should use the
  `Timber.add_exception_context/3` function. However, Timber can
  automatically keep track of errors reported by the VM, so it should
  be uneccessary to call it manually.
  """

  @type t :: %__MODULE__{
    backtrace: [String.t],
    name: String.t,
    message: String.t
  }

  defstruct [:backtrace, :name, :message]
end
