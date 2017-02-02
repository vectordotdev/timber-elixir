defmodule Timber.Events.HTTP do
  def normalize_method(method) do
    method
    |> Atom.to_string()
    |> String.upcase()
    |> String.to_existing_atom()
  end
end