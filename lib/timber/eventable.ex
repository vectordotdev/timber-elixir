defprotocol Timber.Eventable do
  @moduledoc """
  Converts a data structure to a `Timber.Event.t`. This is the heart of how custom events work.
  Any value passed in the `:timber_event` Logger metadata must implement this.

  ## Basic map example

    iex> require Logger
    iex> event_data = %{customer_id: "xiaus1934", amount: 1900, currency: "USD"}
    iex> Logger.info("Payment rejected", timber_event: %{name: :payment_rejected, data: event_data})

  This is the simplest example, and demonstrates Timber's no lock-in / no code debt promise.
  Please see `Timber.Events.CustomEvent` for field explanations.

  ## Using Timber.Events.CustomEvent

    iex> require Logger
    iex> event = Timber.Events.CustomEvent.new(name: :payment_rejected, data: %{customer_id: "xiaus1934", amount: 1900, currency: "USD"})
    iex> Logger.info("Payment rejected", timber_event: event)

  This adds compile time guarantees in exchange for relying on the Timber library. Please see
  `Timber.Events.CustomEvent` for field explanations.

  ## Using your own structured events

    iex> require Logger
    iex> defmodule PaymentRejectedEvent do
    iex>   @derive Timber.Eventable
    iex>   defstruct [:customer_id, :amount, :currency]
    iex> end
    iex> event = %PaymentRejectedEvent{customer_id: "xiaus1934", amount: 1900, currency: "USD"}
    iex> Logger.info("Payment rejected", timber_event: event)

  At Timber, we prefer this, the lock-in to the Timber library is minimal, and it creates
  a stronger contract with any downstream consumers. Such as graphing on the Timber interface,
  alerts, BI tools, etc.

  ## Timing events

  Any of the above examples can pass a `:time_ms` key. This is a special key that Timber
  (and other systems) can use to make assumptions about your data and enhance your experience.
  An example:

    iex> require Logger
    iex> timer = Timber.Timer.start()
    iex> event_data = %{customer_id: "xiaus1934", amount: 1900, currency: "USD"}
    iex> time_ms = Timber.Timer.duration_ms(timer)
    iex> Logger.info("Payment rejected", timber_event: %{name: :payment_rejected, data: event_data, time_ms: time_ms})

  ### Pro tip!

  We recommend defining a `message(t) :: String.t` method or a `message` attribute.
  This works just like the `Exception` behaviour. This way if event creation and logging are
  separated, logging is as simple as:

    iex> require Logger
    iex> {message, metadata} = Timber.Event.logger_tuple(my_internal_event)
    iex> Logger.info(message, metadata)

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
  def to_event(%{name: name, data: data} = event) do
    # Only grab the values we support and then convert to a CustomEvent.
    %Timber.Events.CustomEvent{
      name: name,
      data: data,
      time_ms: Map.get(event, :time_ms, nil),
      message: Map.get(event, :message, nil)
    }
  end
end

defimpl Timber.Eventable, for: Any do
  # Implemented if you want to log your own exceptions. Logging exceptions this
  # way is discouraged, but since our useres cannot redefine this protocol we
  # wanted to make this available for edge cases.
  def to_event(%{__exception__: _value} = exception) do
    Timber.Events.ExceptionEvent.new(exception)
  end

  def to_event(%{__struct__: module} = struct) do
    name =
      module
      |> Timber.Utils.module_name()
      |> String.replace_suffix("Event", "")

    data = Map.from_struct(struct)

    {time_ms, data} = Map.pop(data, :time_ms)

    %Timber.Events.CustomEvent{name: name, data: data, time_ms: time_ms, message: message(struct)}
  end

  # Attempts to extract a message from the data structure, This attemps to follow
  # the pattern set by exceptions.
  # https://github.com/elixir-lang/elixir/blob/44ef53ec2b1f49d86a35a0b33d6c1209fadd3cc8/lib/elixir/lib/exception.ex#L51
  defp message(%{__struct__: module} = struct) do
    try do
      module.message(struct)
    rescue
      _e ->
        case Map.get(struct, :message) do
          message when is_binary(message) -> message
          _val -> nil
        end
    end
  end
end