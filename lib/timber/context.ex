defmodule Timber.Context do
  @moduledoc false
  # Most users will not interact directly with this module and will instead use
  # the helper functions provided by the main `Timber` module. See the `Timber`
  # module for more information.
  #
  # The functions in this module work to modify the context data structure. This
  # module provides us the flexibility to change the context data structure and
  # change how it is modified.

  alias Timber.Contextable

  #
  # Typespecs
  #

  @typedoc """
  Map represeting context
  """
  @type t :: map

  #
  # API
  #

  @doc false
  @spec new :: t
  def new(),
    do: %{}

  @doc false
  @deprecated "Please use Timber.Context.merge/2 instead"
  def add(context, contextable) do
    merge(context, contextable)
  end

  @doc """
  Removes a key from the provided context structure.
  """
  @spec delete(t, atom) :: t
  def delete(context, key) do
    Map.delete(context, key)
  end

  @doc """
  Takes an existing context element and inserts it into the provided context.
  """
  @spec merge(t, Contextable.t()) :: t
  def merge(context, nil),
    do: context

  def merge(context, contextable) do
    additional_context = Contextable.to_context(contextable)
    Map.merge(context, additional_context)
  end
end
