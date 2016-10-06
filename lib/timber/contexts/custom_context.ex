defmodule Timber.Contexts.CustomContext do
  @moduledoc """
  A custom context can be specified by the user that is specific to the system
  being logged.

  To add a custom context to the context stack, you should call
  `Timber.add_custom_context/2`.
  """

  @type t :: %__MODULE__{
    name: String.t,
    data: %{String.t => any}
  }

  defstruct [:name, :data]
end
