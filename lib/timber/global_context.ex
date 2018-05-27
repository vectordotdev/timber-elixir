defmodule Timber.GlobalContext do
  @moduledoc """
  Manages a globally available Timber Context

  This module stores context in Timber's OTP application configuration
  in order to support global writing and reading with high-throughput.
  """

  # The global context is set and maintained in the OTP application configuration
  # under the :global_context key for ease-of-use. The API in this module does
  # not assume that it will always be stored there, so if we find that storing
  # global context here is detrimental, we can easily move it to another methodology.

  alias Timber.Context

  @doc """
  Merges the provided context into the existing context
  """
  @spec add(Context.element()) :: :ok
  def add(context) do
    load()
    |> Context.add(context)
    |> save()
  end

  @doc """
  Dumps the context to a `Context.t`

  This function is provided as a convenience to see the current global
  context.
  """
  @spec get() :: Context.t()
  def get() do
    load()
  end

  @doc """
  Sets the global context, overriding any existing context
  """
  @spec put(Context.t()) :: :ok
  def put(context) do
    save(context)
  end

  @doc false
  @spec load() :: Context.t()
  def load() do
    Application.get_env(:timber, :global_context, Context.new())
  end

  @doc """
  Removes the key from the existing context.
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
    Application.put_env(:timber, :global_context, context)
  end
end
