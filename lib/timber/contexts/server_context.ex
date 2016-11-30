defmodule Timber.Contexts.ServerContext do
  @moduledoc """
  The Server context tracks information about the host your system runs on
  """

  @type t :: %__MODULE__{
    hostname: String.t
  }

  @type m :: %{
    hostname: String.t
  }

  defstruct [:hostname]
end
