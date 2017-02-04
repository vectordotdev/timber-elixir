defmodule Timber.Utils.Module do
  @moduledoc false

  @doc """
  Returns a string representation of the module name with the `Elixir.` prefix stripped.
  """
  def name(module) do
    module
    |> List.wrap()
    |> Module.concat()
    |> Atom.to_string()
    |> String.replace_prefix("Elixir.", "")
  end
end
