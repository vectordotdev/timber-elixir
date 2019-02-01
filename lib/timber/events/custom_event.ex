defmodule Timber.Events.CustomEvent do
  @deprecated_message ~S"""
  The `Timber.Events.CustomEvent` module is deprecated in favor of using simple maps:

      Logger.info(fn ->
        message = "Order #{order_id} placed, total: $#{total}"
        event = %{order_placed: %{id: order_id, total: total}}
        {message, event: event}
      end)

  If you'd like, you can define your events as structs and implement the `Timber.Eventable`
  protocol:

      defmodule OrderPlacedEvent do
        defstruct [:order_id, :total]

        defimpl Timber.Contextable do
          def to_context(event) do
            map = Map.from_struct(event)
            %{order_placed: map}
          end
        end
      end

  Then use it like so:

      Logger.info(fn ->
        event = %OrderPlacedEvent{order_id: "1234", total: 100.45}
        message = OrderPlacedEvent.message(event)
        {message, event: event}
      end)
      
  """

  @moduledoc ~S"""
  **DEPRECATED**

  #{@deprecated_message}
  """

  @type t :: %__MODULE__{
          type: atom(),
          data: map() | nil
        }

  @deprecated @deprecated_message
  defmacro __using__(opts) do
    quote do
      defimpl Timber.Eventable, for: __MODULE__ do
        def to_event(event) do
          type = Keyword.get(unquote(opts), :type, __MODULE__)
          data = Map.from_struct(event)

          %Timber.Events.CustomEvent{type: type, data: data}
          |> Timber.Eventable.to_event()
        end
      end
    end
  end

  @enforce_keys [:type]
  defstruct [
    :data,
    :type
  ]

  defimpl Timber.Eventable do
    def to_event(event) do
      %{event.type => event.data}
    end
  end
end
