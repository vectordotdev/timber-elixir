defprotocol Timber.Contextable do
  @moduledoc """
  Converts a data structure into a `Timber.Context.t`. This is called on any data structure passed
  in the `Timber.add_context/1` function.

  For example, this protocol is how we're able to support `Keyword.t` types:

  ```elixir
  Timber.add_context(build: %{version: "1.0"})
  ```

  This is achieved by:

  ```elixir
  defimpl Timber.Contextable, for: Map do
    def to_context(map) when map_size(map) == 1 do
      [type] = Map.keys(map)
      [data] = Map.values(map)
      %Timber.Contexts.CustomContext{
        type: type,
        data: data
      }
    end
  end
  ```

  ## What about custom contexts and structs?

  If you decide to get more formal with you event definition strategy you can use this
  like you would any other protocol:

  ```elixir
  def OrderPlacedEvent do
    defstruct [:id, :total]

    defimpl Timber.Contextable do
      def to_context(event) do
        Map.from_struct(event)
      end
    end
  end
  ```

  """

  @doc """
  Converts the data structure into a `Timber.Context.t`.
  """
  @spec to_context(map() | list()) :: map()
  def to_context(data)
end

defimpl Timber.Contextable, for: List do
  def to_context(list) do
    if Keyword.keyword?(list) do
      list
      |> Enum.into(%{})
      |> Timber.Contextable.to_context()
    else
      raise "The provided list is not a Keyword.t and therefore cannot be converted " <>
              "to a Timber context"
    end
  end
end

defimpl Timber.Contextable, for: Map do
  def to_context(%{type: type, data: data}) do
    %{type => data}
  end

  def to_context(map),
    do: map
end
