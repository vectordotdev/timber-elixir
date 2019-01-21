defmodule Timber.Contexts.SessionContext do
  @moduledoc ~S"""
  **DEPRECATED**

  This module is deprecated in favor of using `map`s. The next evolution of Timber (2.0)
  no long requires a strict schema and therefore simplifies how users set context:

      Timber.add_context(session: %{id: "abcd1234"})

  In addition, you can use Timber integrations to automatically capture context in `Plug`
  and `Phoenix`:

  * [`:timber_phoenix`](https://github.com/timberio/timber-elixir-phoenix)
  * [`:timber_plug`](https://github.com/timberio/timber-elixir-plug)

  Checkout the `README` for a list of all integrations.
  """

  @type t :: %__MODULE__{
          id: String.t()
        }

  @type m :: %{
          id: String.t()
        }

  defstruct [:id]

  defimpl Timber.Contextable do
    def to_context(context) do
      context = Map.from_struct(context)
      %{session: context}
    end
  end
end
