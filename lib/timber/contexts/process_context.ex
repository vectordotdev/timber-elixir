defmodule Timber.Contexts.ProcessContext do
  @moduledoc """
  Tracks OS process information. Such as the OS process ID.
  """

  @type t :: %__MODULE__{
    id: String.t,
    description: String.t
  }

  @type m :: %{
    id: String.t,
    description: String.t
  }

  defstruct [:id, :description]

  def new(opts) do
    struct(__MODULE__, opts)
  end
end
