defmodule Timber.Contexts.CustomContext do
  @moduledoc """
  The `CustomContext` allows you to track contextual information relevant to your
  system that is not one of the commonly supported contexts for Timber (`Timber.Contexts.*`).

  ## Fields

    * `type` - (atom, required) This is the type of your context. It should be something unique
      and unchanging. It will be used to identify this content. Example: `:my_context`.
    * `data` - (map, optional) A map of data. This can be anything that can be JSON encoded.
      Example: `%{key: "value"}`.

  ## Example

  There are 2 ways to log custom events:

  1. Use a map (simplest)

    ```elixir
    Timber.add_context(build: %{version: "1.0.0"})
    ```

    The root key `:build` is the `type` and the value is the `data`.

  2. Use a struct (advanced)

    Defining structs for your contexts creates a contract around your data structure.
    We recommend this approach when you have downstream consumers that will be affected
    by data structure changes.

    ```elixir
    defmodule BuildContext do
      use Timber.Contexts.CustomContext, type: :build
      @enforce_keys [:version]
      defstruct [:version]
    end

    Timber.add_context(%BuildContext{version: "1.0.0"})
    ```
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
end
