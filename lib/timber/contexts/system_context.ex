defmodule Timber.Contexts.SystemContext do
  @moduledoc ~S"""
  **DEPRECATED**

  This module is deprecated in favor of using `map`s. The next evolution of Timber (2.0)
  no long requires a strict schema and therefore simplifies how users set context:

      Timber.add_context(system: %{hostname: "hostname", pid: "abcd1234"})

  Please note that this context is set automatically for you as part of this library.
  You should not need to do anything to obtain this context.
  """

  @type t :: %__MODULE__{
          hostname: String.t() | nil,
          pid: String.t() | nil
        }

  @type m :: %{
          hostname: String.t() | nil,
          pid: String.t() | nil
        }

  defstruct [:hostname, :pid]

  defimpl Timber.Contextable do
    def to_context(context) do
      context = Map.from_struct(context)
      %{system: context}
    end
  end
end
