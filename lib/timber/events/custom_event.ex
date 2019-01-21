defmodule Timber.Events.CustomEvent do
  @moduledoc ~S"""
  **DEPRECATED**

  This module is deprecated in favor of using simple maps:

      Logger.info(fn ->
        message = "Order #{order_id} placed, total: $#{total}"
        event = %{order_placed: %{id: order_id, total: total}}
        {message, event: event}
      end)

  If you'd like to define your events as structs, you can implement the `Timber.Eventable`
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

  """

  @type t :: %__MODULE__{
          type: atom(),
          data: map() | nil
        }

  defmacro __using__(opts) do
    quote do
      defimpl Timber.Eventable, for: __MODULE__ do
        def to_event(event) do
          type = Keyword.get(unquote(opts), :type, __MODULE__)
          data = Map.from_struct(event)
          %Timber.Events.CustomEvent{type: type, data: data}
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
