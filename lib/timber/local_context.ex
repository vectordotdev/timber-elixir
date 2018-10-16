defmodule Timber.LocalContext do
  @moduledoc """
  Manages Timber context through the `Elixir.Logger` metadata

  This module stores context in the `Elixir.Logger` metadata, so any context is
  specific to the process.

  For more details about the context data structure, see `Timber.Context`.
  """

  alias Timber.Context

  @doc """
  Merges the provided context into the existing context

  `Timber.Context.add/2` is called to merge the existing context
  with the provided context.
  """
  @spec add(Context.element()) :: :ok
  def add(context) do
    load()
    |> Context.add(context)
    |> save()
  end

  @doc """
  Dumps the context to a `Context.t`

  This function is used to expose the current context, which is useful
  if you need to copy the context to a different process.
  """
  @spec get() :: Context.t()
  def get() do
    load()
  end

  @doc """
  Sets the provided context, overriding any existing Context
  """
  @spec put(Context.t()) :: :ok
  def put(context) do
    save(context)
  end

  @doc false
  @spec load() :: Context.t()
  def load() do
    Elixir.Logger.metadata()
    |> extract_from_metadata()
  end

  @doc false
  @spec extract_from_metadata(Keyword.t()) :: Context.t()
  # This function is required by Timber.LogEntry to extract the context
  # from the Logger metadata, so this function _must_ be public, but it
  # is only intended for internal use.
  def extract_from_metadata(metadata) do
    Keyword.get(metadata, :timber_context, Context.new())
  end

  @doc """
  Removes the key from the existing local context.

  `Timber.Context.remove_key/2` is called to delete the key.
  """
  @spec remove_key(atom) :: :ok
  def remove_key(key) do
    load()
    |> Context.remove_key(key)
    |> save()
  end

  @doc false
  @spec save(Context.t()) :: :ok
  def save(context) do
    Elixir.Logger.metadata(timber_context: context)
    :ok
  end
end
