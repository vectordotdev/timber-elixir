defprotocol Timber.Eventable do
  @moduledoc """
  Converts a data structure to a `Timber.Event.t`. This allows you to
  support custom types passed to the Logger metadata `:event` key.

  ## Basic map example

    iex> require Logger
    iex> event_data = %{customer_id: "xiaus1934", amount: 1900, currency: "USD"}
    iex> Logger.info("Payment rejected", event: %{name: :payment_rejected, data: event_data})

  This is the simplest example, and demonstrates Timber's no lock-in / no code debt promise.
  Please see `Timber.Events.CustomEvent` for field explanations.

  ## Using Timber.Events.CustomEvent

    iex> require Logger
    iex> event = Timber.Events.CustomEvent.new(name: :payment_rejected, data: %{customer_id: "xiaus1934", amount: 1900, currency: "USD"})
    iex> Logger.info("Payment rejected", event: event)

  This adds compile time guarantees in exchange for relying on the Timber library. Please see
  `Timber.Events.CustomEvent` for field explanations.

  ## Timing events

  Any of the above examples can pass a `:time_ms` key in the `:data` map. This is a special key
  that Timber (and other systems) can use to enhance your experience. An example:

    iex> require Logger
    iex> timer = Timber.Timer.start()
    iex> # ... code to time ...
    iex> time_ms = Timber.Timer.duration_ms(timer)
    iex> event_data = %{customer_id: "xiaus1934", amount: 1900, currency: "USD", time_ms: time_ms}
    iex> Logger.info("Payment rejected", event: %{name: :payment_rejected, data: event_data})

  ## Pro tip! Use your own structs.

  At Timber we prefer to define our events as structs. It provides a stronger contract with
  downstream consumers (alerts, graphs, etc), and there is no risk of code-debt or lock-in
  to Timber. You are simply adding events to your application. Here's an example:

  First, implement the `Timber.Eventable` protocol:

    iex> defimpl Timber.Eventable, for: Any do
    iex>   def to_event(%{__struct__: module} = event) do
    iex>     name = module.name()
    iex>     data = Map.from_struct(event)
    iex>     Timber.Events.CustomEvent.new(name: name, data: data)
    iex>   end
    iex> end

  Notice we expect every event to have a `name` function, Timber requires this for custom events.
  Let's define a behaviour to ensure all events follow this pattern:

    iex> defmodule MyApp.Event do
    iex>   @callback name(struct()) :: atom()
    iex> end

  Lastly, define your event and log it!:

    iex> require Logger
    iex> defmodule PaymentRejectedEvent do
    iex>   @behaviour MyApp.Event
    iex>   @derive Timber.Eventable
    iex>   defstruct [:customer_id, :amount, :currency]
    iex>   def name(_event), do: :payment_rejected
    iex> end
    iex> event = %PaymentRejectedEvent{customer_id: "xiaus1934", amount: 1900, currency: "USD"}
    iex> Logger.info("Payment rejected", event: event)

  Note: we recommend adding a `@callback message(struct()) :: String.t` to `MyApp.Event`.
  This follows the same pattern set by the `Exception` behaviour. This way if event creation
  and logging are separated, logging an event is as simple as:

      message = MyApp.Event.message(event)
      Logger.info(message, event: event)

  """

  @spec to_event(any()) :: t
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

defimpl Timber.Eventable, for: Timber.Events.HTTPRequestEvent do
  def to_event(event), do: event
end

defimpl Timber.Eventable, for: Timber.Events.HTTPResponseEvent do
  def to_event(event), do: event
end

defimpl Timber.Eventable, for: Timber.Events.SQLQueryEvent do
  def to_event(event), do: event
end

defimpl Timber.Eventable, for: Timber.Events.TemplateRenderEvent do
  def to_event(event), do: event
end

defimpl Timber.Eventable, for: Map do
  def to_event(%{name: name, data: data}) do
    %Timber.Events.CustomEvent{
      name: name,
      data: data
    }
  end
end