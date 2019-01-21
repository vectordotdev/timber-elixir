defprotocol Timber.Eventable do
  @moduledoc """
  Converts a data structure into a `Timber.Event.t`. This is called on any data structure passed
  in the `:event` metadata key passed to `Logger`.

  For example, this protocol is how we're able to support maps:

  ```elixir
  event_data = %{
    payment_rejected: %{customer_id: "xiaus1934", amount: 1900, currency: "USD"}
  }
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

  @fallback_to_any true

  @doc """
  Converts the data structure into a `Timber.Event.t`.
  """
  @spec to_event(any) :: Timber.Event.t()
  def to_event(data)
end

defimpl Timber.Eventable, for: Map do
  def to_event(%{type: type, data: data}) do
    %{type => data}
  end

  def to_event(map) do
    map
  end
end

defimpl Timber.Eventable, for: Any do
  def to_event(%{__exception__: true} = error) do
    error
    |> Timber.Events.ErrorEvent.from_exception()
    |> Timber.Eventable.to_event()
  end
end
