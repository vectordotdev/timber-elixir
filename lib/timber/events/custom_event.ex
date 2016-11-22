defmodule Timber.Events.CustomEvent do
  @moduledoc """
  Allows for custom events that aren't covered elsewhere.

  Custom events can be used to encode information about events that are central
  to your line of business like receiving credit card payments, adding products
  to a card, saving a draft of a post, or changing a user's password.

  Event data can include anything that adheres to the `Poison.Encoder` protocol.
  That is, anything that can be encoded to JSON, including nested maps.

  Let's take a look at a basic example:

    iex> require Logger
    iex> defmodule PaymentReceivedEvent do
    iex>   use Timber.Events.CustomEvent
    iex>   defstruct [:customer_id, :amount, :currency]
    iex> end
    iex> event = PaymentReceivedEvent.new(customer_id: "xiaus1934", amount: 1900, currency: "USD")
    iex> Logger.info("Payment received", timber_event: event)

  The resulting log line will be augmented with your event data and Timber will
  display the event with same name as your module.

  You can also add timing details to your events:

    iex> require Logger
    iex> defmodule PaymentReceivedEvent do
    iex>   use Timber.Events.CustomEvent
    iex>   defstruct [:customer_id, :amount, :currency]
    iex> end
    iex> timer = Timber.start_timing()
    iex> # ... code to time ...
    iex> event = PaymentReceivedEvent.new(customer_id: "xiaus1934", amount: 1900, currency: "USD", timer: timer)
    iex> Logger.info("Received payment", timber_event: event)

  """

  alias Timber.Timer

  @type t :: %__MODULE__{
    name: String.t,
    data: map | nil,
    time_ms: float() | nil
  }

  @doc false
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @behaviour Timber.Events.CustomEvent

      def new(opts) do
        opts = Keyword.put(opts, :__timber_custom_event__, true)

        timer = Keyword.get(opts, :timer)
        opts =
          if timer do
            time_ms = Timer.duration_ms(timer)
            opts
            |> Keyword.delete(:timer)
            |> Keyword.put(:time_ms, time_ms)
          else
            opts
          end

        struct(__MODULE__, opts)
      end

      def data(_event) do
        %{}
      end

      def name(event) do
        __MODULE__
        |> List.wrap()
        |> Module.concat()
        |> Atom.to_string()
      end
    end
  end

  @callback data(t) :: map()
  @callback name(t) :: String.t

  @enforce_keys [:name]
  defstruct [
    :data,
    :name,
    :time_ms
  ]

  def new(%{__struct__: module, __timber_custom_event__: true} = event) do
    %__MODULE__{
      data: module.data(event),
      name: module.name(event),
      time_ms: Map.get(event, :time_ms, nil)
    }
  end
end
