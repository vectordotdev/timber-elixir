defmodule Timber.Context do
  @moduledoc """
  The ContextEntry module formalizes the structure of context stack entries

  Most users will not interact directly with this module and will instead use
  the helper functions provided by the main `Timber` module. See the `Timber`
  module for more information.
  """

  alias Timber.Contexts
  alias Timber.Utils.Map, as: UtilsMap

  @type context_data ::
    Contexts.CustomContext.t        |
    Contexts.HTTPContext.t          |
    Contexts.OrganizationContext.t  |
    Contexts.ProcessContext.t       |
    Contexts.ServerContext.t        |
    Contexts.UserContext.t

  @type t :: %{
    optional(:custom) => Context.CustomContext.m,
    optional(:http_request) => Context.HTTPContext.m,
    optional(:organization) => Context.OrganizationContext.m,
    optional(:process) => Context.ProcessContext.m,
    optional(:server) => Context.ServerContext.m,
    optional(:user) => Context.UserContext.m
  }

  @doc false
  def new(), do: %{}

  @doc """
  Takes an existing context and inserts the new context
  """
  @spec add_context(t, context_data) :: t
  def add_context(existing_context_map, %Contexts.CustomContext{type: type, data: data} = context_element) do
    key = type_for_data(context_element)
    custom_map =
      existing_context_map
      |> Map.get(key, %{})
      |> Map.put(type, data)
    Map.put(existing_context_map, key, custom_map)
  end
  def add_context(existing_context_map, context_element) do
    key = type_for_data(context_element)

    Map.from_struct(context_element)
    |> UtilsMap.recursively_drop_blanks()
    |> insert_context(existing_context_map, key)
  end

  @spec insert_context(map, t, atom) :: map
  defp insert_context(new_context, existing_context, _key) when map_size(new_context) == 0 do
    existing_context
  end
  defp insert_context(new_context, existing_context, key) do
    Map.put(existing_context, key, new_context)
  end

  @spec type_for_data(context_data) :: atom
  defp type_for_data(%Contexts.CustomContext{}), do: :custom
  defp type_for_data(%Contexts.HTTPContext{}), do: :http
  defp type_for_data(%Contexts.OrganizationContext{}), do: :organization
  defp type_for_data(%Contexts.ProcessContext{}), do: :process
  defp type_for_data(%Contexts.ServerContext{}), do: :server
  defp type_for_data(%Contexts.UserContext{}), do: :user
end
