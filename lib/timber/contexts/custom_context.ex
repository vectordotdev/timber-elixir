defmodule Timber.Contexts.CustomContext do
  @moduledoc """
  A custom context can be specified by the user that is specific to the system
  being logged.

  You can use a custom context to track contextual information relevant to your
  system that is not one of the commonly supported contexts for Timber.

  ## Fields

    * `type` - (atom, required) This is the type of your context. It should be something unique
      and unchanging. It will be used to identify this content. Example: `:my_context`.
    * `data` - (map, optional) A map of data. This can be anything that can be JSON encoded.
      Example: `%{key: "value"}`.

  ## Example

    %Timber.Contexts.CustomContext{type: :my_custom_context, data: %{"key" => "value"}}
    |> Timber.add_context()

  """

  @type t :: %__MODULE__{
    type: atom(),
    data: %{String.t => any}
  }

  @type m :: %{
    type: atom(),
    data: %{String.t => any}
  }

  @enforce_keys [:type]
  defstruct [:type, :data]
end
