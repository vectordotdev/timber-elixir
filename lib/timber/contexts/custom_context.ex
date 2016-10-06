defmodule Timber.Contexts.CustomContext do
  @moduledoc """
  A custom context can be specified by the user that is specific to the system
  being logged.

  You can use a custom context to track contextual information relevant to your
  system that is not one of the commonly supported contexts for Timber.
  """

  @type t :: %__MODULE__{
    name: String.t,
    data: %{String.t => any}
  }

  defstruct [:name, :data]
end
