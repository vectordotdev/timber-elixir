defmodule Timber.Contexts.HTTPContext do
  @moduledoc ~S"""
  **DEPRECATED**

  This module is deprecated in favor of using `map`s. The next evolution of Timber (2.0)
  no long requires a strict schema and therefore simplifies how users set context:

      Timber.add_context(http: %{method: "post", path: "/checkout"})

  In addition, you can use Timber integrations to automatically capture context in `Plug`
  and `Phoenix`:

  * [`:timber_phoenix`](https://github.com/timberio/timber-elixir-phoenix)
  * [`:timber_plug`](https://github.com/timberio/timber-elixir-plug)

  Checkout the `README` for a list of all integrations.
  """

  @type t :: %__MODULE__{
          method: String.t(),
          path: String.t(),
          request_id: String.t() | nil,
          remote_addr: String.t() | nil
        }

  @type m :: %{
          :method => String.t(),
          :path => String.t(),
          optional(:request_id) => String.t(),
          optional(:remote_addr) => String.t()
        }

  defstruct [:method, :path, :request_id, :remote_addr]

  defimpl Timber.Contextable do
    def to_context(context) do
      context = Map.from_struct(context)
      %{http: context}
    end
  end
end
