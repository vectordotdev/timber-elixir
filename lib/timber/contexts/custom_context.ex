defmodule Timber.Contexts.CustomContext do
  @moduledoc ~S"""
  **DEPRECATED**

  The `Timber.Contexts.CustomContext` module is deprecated in favor of using simple maps:

      Timber.add_context(build: %{version: "1.0.0"})

  If you'd like, you can define your contexts as structs and implement the `Timber.Contextable`
  protocol:

      defmodule BuildContext do
        defstruct [:version]

        defimpl Timber.Contextable do
          def to_context(context) do
            map = Map.from_struct(context)
            %{build: map}
          end
        end
      end
  """

  @type t :: %__MODULE__{
          type: atom(),
          data: %{String.t() => any}
        }

  @type m :: %{
          type: atom(),
          data: %{String.t() => any}
        }

  @enforce_keys [:type]
  defstruct [:type, :data]

  defimpl Timber.Contextable do
    def to_context(context) do
      %{context.type => context.data}
    end
  end
end
