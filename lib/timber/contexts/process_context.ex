defmodule Timber.Contexts.ProcessContext do
  @moduledoc """
  Tracks process information
  """

  @type t :: %__MODULE__{
    id: String.t,
    description: String.t
  }

  defstruct [:id, :description]

  def new(opts) do
    struct(__MODULE__, opts)
  end
end
