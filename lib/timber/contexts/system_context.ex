defmodule Timber.Contexts.SystemContext do
  @moduledoc """
  Tracks system information such as the current Process ID (pid).
  """

  @type t :: %__MODULE__{
    hostname: String.t | nil,
    pid: String.t | nil
  }

  @type m :: %{
    hostname: String.t | nil,
    pid: String.t | nil
  }

  defstruct [:hostname, :pid]
end
