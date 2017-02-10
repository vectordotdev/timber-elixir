defmodule Timber.Contexts.ProcessContext do
  @moduledoc """
  Tracks process information
  """

  @type t :: %__MODULE__{
    pid: String.t
  }

  @type m :: %{
    pid: String.t
  }

  defstruct [:pid]
end
