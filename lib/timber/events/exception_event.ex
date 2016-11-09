defmodule Timber.Events.ExceptionEvent do
  @moduledoc """
  The exception event is used to track exceptions.

  Timber can automatically keep track of errors reported by the VM by hooking
  into the SASL reporting system to collect exception information, so it should
  be unnecessary to track exceptions manually.
  """

  @type t :: %__MODULE__{
    backtrace: [String.t],
    name: String.t,
    message: String.t
  }

  defstruct [:backtrace, :name, :message]
end
