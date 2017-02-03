defmodule Timber.Events.HTTP do
  @moduledoc """
  Utility module for common HTTP related events.
  """

  def normalize_method(method) do
    method
    |> Atom.to_string()
    |> String.upcase()
    |> String.to_existing_atom()
  end
end