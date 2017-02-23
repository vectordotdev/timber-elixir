defmodule Timber.Context do
  @moduledoc """
  The ContextEntry module formalizes the structure of context stack entries

  Most users will not interact directly with this module and will instead use
  the helper functions provided by the main `Timber` module. See the `Timber`
  module for more information.
  """

  alias Timber.Contexts
  alias Timber.Utils.Map, as: UtilsMap

  @type context_element ::
    Contexts.CustomContext.t        |
    Contexts.HTTPContext.t          |
    Contexts.OrganizationContext.t  |
    Contexts.ServerContext.t        |
    Contexts.SystemContext.t        |
    Contexts.UserContext.t

  @type t :: %{
    optional(:custom) => Context.CustomContext.m,
    optional(:http_request) => Context.HTTPContext.m,
    optional(:organization) => Context.OrganizationContext.m,
    optional(:server) => Context.ServerContext.m,
    optional(:system) => Context.SystemContext.m,
    optional(:user) => Context.UserContext.m
  }

  @doc false
  def new(), do: %{}

  @doc """
  Takes an existing context element and inserts it into the global context.
  """
  @spec add(t, context_element) :: t
  def add(context, %Contexts.CustomContext{type: type} = context_element) when is_binary(type) do
    new_context_element = %{context_element | type: String.to_atom(type)}
    add(context, new_context_element)
  end

  def add(context, %Contexts.CustomContext{} = context_element) do
    key = type(context_element)
    api_map = to_api_map(context_element)
    insert(context, key, api_map)
  end

  def add(existing_context_map, context_element) do
    key = type(context_element)
    context_element_map = to_api_map(context_element)
    insert(existing_context_map, key, context_element_map)
  end

  # Inserts the context_element into the main context map
  @spec insert(map, t, atom) :: map
  defp insert(existing_context, _key, new_context) when map_size(new_context) == 0 do
    existing_context
  end

  defp insert(existing_context, key, new_context) do
    Map.put(existing_context, key, new_context)
  end

  # Converts a context_element into a map the Timber API expects.
  @spec to_api_map(context_element) :: map
  defp to_api_map(%Contexts.CustomContext{type: type, data: data}) do
    %{type => data}
    |> UtilsMap.recursively_drop_blanks()
  end

  defp to_api_map(%Contexts.OrganizationContext{id: id} = context_element) when is_integer(id) do
    to_api_map(%{context_element | id: Integer.to_string(id)})
  end

  defp to_api_map(%Contexts.SystemContext{pid: pid} = context_element) when is_integer(pid) do
    to_api_map(%{context_element | pid: Integer.to_string(pid)})
  end

  defp to_api_map(%Contexts.UserContext{id: id} = context_element) when is_integer(id) do
    to_api_map(%{context_element | id: Integer.to_string(id)})
  end

  defp to_api_map(context_element) do
    context_element
    |> Map.from_struct()
    |> UtilsMap.recursively_drop_blanks()
  end

  # Determines the key name for the context_element that the Timber API expects.
  @spec type(context_element) :: atom
  defp type(%Contexts.CustomContext{}), do: :custom
  defp type(%Contexts.HTTPContext{}), do: :http
  defp type(%Contexts.OrganizationContext{}), do: :organization
  defp type(%Contexts.RuntimeContext{}), do: :runtime
  defp type(%Contexts.ServerContext{}), do: :server
  defp type(%Contexts.SystemContext{}), do: :system
  defp type(%Contexts.UserContext{}), do: :user
end
