defmodule Timber.Contexts.SystemContext do
  @moduledoc """
  Tracks system information such as the current Process ID (pid).
  """

  @type t :: %__MODULE__{
    pid: String.t
  }

  @type m :: %{
    pid: String.t
  }

  defstruct [:pid]
end
