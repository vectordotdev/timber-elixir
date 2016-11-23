defprotocol Timber.Event do
  @moduledoc """
  Converts a data structure to a map that the Timber API can understand. This is the heart
  of how custom events are implemented. Any data structure passed in the `:timber_event`
  Logger metadata key must implement this.

  ## Basic map example

    iex> require Logger
    iex> event_data = %{customer_id: "xiaus1934", amount: 1900, currency: "USD"}
    iex> Logger.info("Payment rejected", timber_event: %{name: :payment_rejected, data: event_data})

  This is the simplest example, and demonstrates Timber's no lock-in / no code debt promise.
  Note that this map is simple being converted to a `Timber.Events.CustomEvent`. Please see that
  module for field explanations.

  ## Using Timber.Events.CustomEvent

    iex> require Logger
    iex> event = Timber.Events.CustomEvent.new(name: :payment_rejected, data: %{customer_id: "xiaus1934", amount: 1900, currency: "USD"})
    iex> Logger.info("Payment rejected", timber_event: event)

  This adds a little more structure to logging events.

  ## Using your own structured events

    iex> require Logger
    iex> defmodule PaymentRejectedEvent do
    iex>   @derive Timber.Event
    iex>   defstruct [:customer_id, :amount, :currency]
    iex> end
    iex> event = %PaymentRejectedEvent{customer_id: "xiaus1934", amount: 1900, currency: "USD"}
    iex> Logger.info("Payment rejected", timber_event: event)

  At Timber, we prefer this method, it follows suit with how we define exceptions, and it creates
  a stronger contract. There are a number of down stream consumers that use these events. Such as
  graphing on the Timber interface, alerts, and other BI tools.

  """

  @type t ::
    Events.ControllerCallEvent  |
    Events.CustomEvent          |
    Events.ExceptionEvent       |
    Events.HTTPRequestEvent     |
    Events.HTTPResponseEvent    |
    Events.SQLQueryEvent        |
    Events.TemplateRenderEvent

  @spec to_event(any()) :: t
  def to_event(data)
end

defimpl Timber.Event, for: Timber.Events.ControllerCallEvent do
  def to_event(event), do: event
end

defimpl Timber.Event, for: Timber.Events.CustomEvent do
  def to_event(event), do: event
end

defimpl Timber.Event, for: Timber.Events.ExceptionEvent do
  def to_event(event), do: event
end

defimpl Timber.Event, for: Timber.Events.HTTPRequestEvent do
  def to_event(event), do: event
end

defimpl Timber.Event, for: Timber.Events.HTTPResponseEvent do
  def to_event(event), do: event
end

defimpl Timber.Event, for: Timber.Events.SQLQueryEvent do
  def to_event(event), do: event
end

defimpl Timber.Event, for: Timber.Events.TemplateRenderEvent do
  def to_event(event), do: event
end

defimpl Timber.Event, for: Map do
  def to_event(%{name: name, data: data} = event) do
    # Only grab the values we support and then convert to a CustomEvent.
    %Timber.Events.CustomEvent{name: name, data: data, time_ms: Map.get(event, :time_ms, nil)}
  end
end

defimpl Timber.Event, for: Any do
  def to_event(%{__struct__: module} = struct) do
    name =
      module
      |> Utils.module_name()
      |> String.replace_suffix("Event", "")

    data = Map.from_struct(struct)

    {time_ms, data} = Map.pop(data, :time_ms)

    %Timber.Events.CustomEvent{name: name, data: data, time_ms: time_ms}
  end
end