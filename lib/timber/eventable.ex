defprotocol Timber.Eventable do
  @moduledoc """
  Converts a data structure into a `Timber.Event.t`. This is called on any data structure passed
  in the `:event` metadata key passed to `Logger`.

  For example, this protocol is how we're able to support maps:

  ```elixir
  event_data = %{customer_id: "xiaus1934", amount: 1900, currency: "USD"}
  Logger.info "Payment rejected", event: event_data
  ```

  This is achieved by:

  ```elixir
  defimpl Timber.Eventable, for: Map do
    def to_event(%{type: type, data: data}) do
      %Timber.Events.CustomEvent{
        type: type,
        data: data
      }
    end
  end
  ```

  ## What about custom events and structs?

  We recommend defining a struct and calling `use Timber.Events.CustomEvent` in that module.
  This takes care of everything automatically. See `Timber.Events.CustomEvent` for examples.
  """

  @doc """
  Converts the data structure into a `Timber.Event.t`.
  """
  @spec to_event(any()) :: Timber.Event.t
  def to_event(data)
end

defimpl Timber.Eventable, for: Timber.Events.ControllerCallEvent do
  def to_event(event), do: event
end

defimpl Timber.Eventable, for: Timber.Events.CustomEvent do
  def to_event(event), do: event
end

defimpl Timber.Eventable, for: Timber.Events.ExceptionEvent do
  def to_event(event), do: event
end

defimpl Timber.Eventable, for: Timber.Events.HTTPClientRequestEvent do
  def to_event(event), do: event
end

defimpl Timber.Eventable, for: Timber.Events.HTTPClientResponseEvent do
  def to_event(event), do: event
end

defimpl Timber.Eventable, for: Timber.Events.HTTPServerRequestEvent do
  def to_event(event), do: event
end

defimpl Timber.Eventable, for: Timber.Events.HTTPServerResponseEvent do
  def to_event(event), do: event
end

defimpl Timber.Eventable, for: Timber.Events.SQLQueryEvent do
  def to_event(event), do: event
end

defimpl Timber.Eventable, for: Timber.Events.TemplateRenderEvent do
  def to_event(event), do: event
end

defimpl Timber.Eventable, for: Map do
  def to_event(%{type: type, data: data}) do
    %Timber.Events.CustomEvent{
      type: type,
      data: data
    }
  end

  def to_event(map) when map_size(map) == 1 do
    [type] = Map.keys(map)
    [data] = Map.values(map)
    %Timber.Events.CustomEvent{
      type: type,
      data: data
    }
  end
end