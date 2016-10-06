defmodule Timber.Contexts.ServerContext do
  @type t :: %__MODULE__{
    hostname: String.t
  }

  defstruct [:hostname]
end
