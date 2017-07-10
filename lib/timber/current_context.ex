defmodule Timber.CurrentContext do
  @moduledoc """
  Represents the current context stored in the `Elixir.Logger` metadata.
  This module's sole purposes is to load and persist context from that metadata.
  The actual context data structure is defined and managed in `Timber.Context`.
  """

  alias Timber.Context

  @doc """
  Loads the current context from the `Elixir.Logger` metadata.
  """
  @spec load :: Context.t
  def load do
    Elixir.Logger.metadata()
    |> extract()
  end

  @doc false
  @spec extract(Keyword.t) :: Context.t
  def extract(metadata) do
    Keyword.get(metadata, :timber_context, Context.new())
  end

  @doc """
  Save the provided context into the `Elixir.Logger` metadata.
  """
  @spec save(Context.t) :: :ok
  def save(context) do
    Elixir.Logger.metadata([timber_context: context])
    :ok
  end
end