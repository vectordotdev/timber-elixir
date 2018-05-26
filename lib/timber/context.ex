defmodule Timber.Context do
  @moduledoc """
  The ContextEntry module formalizes the structure of context stack entries

  Most users will not interact directly with this module and will instead use
  the helper functions provided by the main `Timber` module. See the `Timber`
  module for more information.

  The functions in this module work by modifying the Logger metadata store which
  is unique to every BEAM process. This is convenient in many ways. First and
  foremost, it does not require you to manually manage the metadata. Second,
  because we conform to the standard Logger principles, you can utilize Timber
  alongside other Logger backends without issue. Timber prefixes its contextual
  metadata keys so as not to interfere with other systems.
  """

  alias Timber.Contextable
  alias Timber.Contexts
  alias Timber.Utils.Map, as: UtilsMap

  @typedoc """
  Deprecated; please use `element` instead
  """
  @type context_element :: element

  @type element ::
          map
          | Keyword.t()
          | Contexts.CustomContext.t()
          | Contexts.HTTPContext.t()
          | Contexts.JobContext.t()
          | Contexts.OrganizationContext.t()
          | Contexts.RuntimeContext.t()
          | Contexts.SessionContext.t()
          | Contexts.SystemContext.t()
          | Contexts.UserContext.t()

  @type t :: %{
          optional(:custom) => Contexts.CustomContext.m(),
          optional(:http) => Contexts.HTTPContext.m(),
          optional(:job) => Contexts.JobContext.m(),
          optional(:organization) => Contexts.OrganizationContext.m(),
          optional(:runtime) => Contexts.RuntimeContext.m(),
          optional(:session) => Contexts.SessionContext.m(),
          optional(:system) => Contexts.SystemContext.m(),
          optional(:user) => Contexts.UserContext.m()
        }

  @doc false
  def new(), do: %{}

  @doc """
  Takes an existing context element and inserts it into the provided context.
  """
  @spec add(t, element) :: t
  def add(context, %Contexts.CustomContext{type: type} = context_element) when is_binary(type) do
    new_context_element = %{context_element | type: String.to_atom(type)}
    add(context, new_context_element)
  end

  def add(context, %Contexts.CustomContext{} = context_element) do
    key = type(context_element)
    api_map = to_api_map(context_element)
    insert(context, key, api_map)
  end

  def add(context, data) when is_list(data) do
    Enum.reduce(data, context, fn item, context ->
      add(context, item)
    end)
  end

  def add(context, {key, val}) do
    add(context, %{key => val})
  end

  def add(context, data) do
    context_element = Contextable.to_context(data)
    key = type(context_element)
    context_element_map = to_api_map(context_element)
    insert(context, key, context_element_map)
  end

  # Inserts the context_element into the main context map
  @spec insert(t, atom, t) :: map
  defp insert(context, _key, new_context) when map_size(new_context) == 0 do
    context
  end

  defp insert(%{custom: custom_context} = context, :custom, new_context) do
    merged_custom_context = Map.merge(custom_context, new_context)
    Map.put(context, :custom, merged_custom_context)
  end

  defp insert(context, key, new_context) do
    Map.put(context, key, new_context)
  end

  @doc """
  Merges two Context structs

  Entries in the second Context will override entries in the first.
  The caveat to this is custom context, which will descend into the
  custom context and merge it there. Even then, custom context entries
  in the second will override custom context entries in the first.
  """
  @spec merge(t, t) :: t
  def merge(context, nil), do: context

  def merge(first_context, second_context) do
    Map.merge(first_context, second_context, &c_merge/3)
  end

  defp c_merge(:custom, first_context, second_context) do
    Map.merge(first_context, second_context)
  end

  defp c_merge(_key, first_context, _second_context) do
    first_context
  end

  # Converts a context_element into a map the Timber API expects.
  @spec to_api_map(element) :: map
  defp to_api_map(%Contexts.CustomContext{type: type, data: data}) do
    %{type => data}
    |> UtilsMap.recursively_drop_blanks()
  end

  defp to_api_map(%Contexts.JobContext{id: id} = context_element) when is_integer(id) do
    to_api_map(%{context_element | id: Integer.to_string(id)})
  end

  defp to_api_map(%Contexts.OrganizationContext{id: id} = context_element) when is_integer(id) do
    to_api_map(%{context_element | id: Integer.to_string(id)})
  end

  defp to_api_map(%Contexts.SessionContext{id: id} = context_element) when is_integer(id) do
    to_api_map(%{context_element | id: Integer.to_string(id)})
  end

  defp to_api_map(%Contexts.SystemContext{pid: pid} = context_element) when is_binary(pid) do
    pid =
      case Integer.parse(pid) do
        {pid, _units} -> pid
        _ -> nil
      end

    to_api_map(%{context_element | pid: pid})
  end

  defp to_api_map(%Contexts.UserContext{id: id} = context_element) when is_integer(id) do
    to_api_map(%{context_element | id: Integer.to_string(id)})
  end

  defp to_api_map(context_element) do
    context_element
    |> UtilsMap.deep_from_struct()
    |> UtilsMap.recursively_drop_blanks()
  end

  # Determines the key name for the context_element that the Timber API expects.
  @spec type(element) :: atom
  defp type(%Contexts.CustomContext{}), do: :custom
  defp type(%Contexts.HTTPContext{}), do: :http
  defp type(%Contexts.JobContext{}), do: :job
  defp type(%Contexts.OrganizationContext{}), do: :organization
  defp type(%Contexts.RuntimeContext{}), do: :runtime
  defp type(%Contexts.SessionContext{}), do: :session
  defp type(%Contexts.SystemContext{}), do: :system
  defp type(%Contexts.UserContext{}), do: :user
end
