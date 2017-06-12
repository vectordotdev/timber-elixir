defprotocol Timber.Contextable do
  @moduledoc """
  Converts a data structure into a `Timber.Context.t`. This is called on any data structure passed
  in the `Timber.add_context/1` function.

  For example, this protocol is how we're able to support maps:

  ```elixir
  context_data = %{type: :build, data: %{version: "1.0"}}
  Timber.add_context(context_data)
  ```

  This is achieved by:

  ```elixir
  defimpl Timber.Contextable, for: Map do
    def to_context(%{type: type, data: data}) do
      %Timber.Contexts.CustomContext{
        type: type,
        data: data
      }
    end
  end
  ```

  ## What about custom contexts and structs?

  We recommend defining a struct and calling `use Timber.Contexts.CustomContext` in that module.
  This takes care of everything automatically. See `Timber.Contexts.CustomContext` for examples.
  """

  @doc """
  Converts the data structure into a `Timber.Event.t`.
  """
  @spec to_context(any()) :: Timber.Context.t
  def to_context(data)
end

defimpl Timber.Contextable, for: Timber.Contexts.CustomContext do
  def to_context(context), do: context
end

defimpl Timber.Contextable, for: Timber.Contexts.HTTPContext do
  def to_context(context), do: context
end

defimpl Timber.Contextable, for: Timber.Contexts.JobContext do
  def to_context(context), do: context
end

defimpl Timber.Contextable, for: Timber.Contexts.OrganizationContext do
  def to_context(context), do: context
end

defimpl Timber.Contextable, for: Timber.Contexts.SessionContext do
  def to_context(context), do: context
end

defimpl Timber.Contextable, for: Timber.Contexts.SystemContext do
  def to_context(context), do: context
end

defimpl Timber.Contextable, for: Timber.Contexts.UserContext do
  def to_context(context), do: context
end

defimpl Timber.Contextable, for: Map do
  def to_context(%{type: type, data: data}) do
    %Timber.Contexts.CustomContext{
      type: type,
      data: data
    }
  end

  def to_context(map) when map_size(map) == 1 do
    [type] = Map.keys(map)
    [data] = Map.values(map)
    %Timber.Contexts.CustomContext{
      type: type,
      data: data
    }
  end
end