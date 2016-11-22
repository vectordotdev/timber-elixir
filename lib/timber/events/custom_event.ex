defmodule Timber.Events.CustomEvent do
  @moduledoc """
  Allows for custom events that aren't covered elsewhere.

  Custom events can be used to encode information about events that are central
  to your line of business like receiving credit card payments, adding products
  to a card, saving a draft of a post, or changing a user's password.

  Event data can include anything that adheres to the `Poison.Encoder` protocol.
  That is, anything that can be encoded to JSON, including nested maps.

  ## Examples

  Basic example:

    iex> require Logger
    iex> event_data = %{_name: :payment_received, _time_ms: 45.6, customer_id: "xiaus1934", amount: 1900, currency: "USD"}
    iex> Logger.info("Received payment", timber_event: event_data)

  Note that `_name` and `_time_ms` are optional. The above adheres to Timber's no lock-in /
  no code debt policy. But if you're going to log events throughout your app, we recommend doing
  so with more structure:

    iex> require Logger
    iex> timer = Timber.start_timing() # optional
    iex> # ... code to time ...
    iex> event_data = %{customer_id: "xiaus1934", amount: 1900, currency: "USD"}
    iex> event = Timber.event(name: :payment_received, data: event_data, timer: timer)
    iex> Logger.info("Received payment", timber_event: event)

  And lastly, if you're like us at Timber, you'll want to define structs for each event,
  similar to exceptions:

    iex> require Logger
    iex> defmodule PaymentReceivedEvent do
    iex>   use Timber.Events.CustomEvent
    iex>   defstruct [:customer_id, :amount, :currency]
    iex> end
    iex> timer = Timber.start_timing() # optional
    iex> # ... code to time ...
    iex> event = PaymentReceivedEvent.new(customer_id: "xiaus1934", amount: 1900, currency: "USD", timer: timer)
    iex> Logger.info("Received payment", timber_event: event)

  `PaymentReceivedEvent`, will be used as the event name unless a `_name` attribute is supplied.
  """

  alias Timber.{Timer, Utils}

  @type t :: %__MODULE__{
    name: String.t,
    data: map() | nil,
    time_ms: float() | nil
  }

  @doc false
  defmacro __using__(_opts) do
    quote do
      def new(opts) do
        opts = Timer.convert_to_time_ms(opts, :timer, :_time_ms)
        struct(__MODULE__, opts)
      end
    end
  end

  @enforce_keys [:name]
  defstruct [
    :data,
    :name,
    :time_ms
  ]

  @doc ~S"""
  Creates a new custom event. See the module docs for `Timber.Events.CustomEvent` for examples.

  ## Options

  - `:name` - The name of the event
  - `:data` - A map of data. Anything that can be JSON encoded, include nested maps.
  - `:timer` - The result from `Timer.Timer.start()`. We'll automatically calculate the duration
               in milliseconds in a 4 decimal precision.
  """
  def new(opts) do
    opts = Timer.convert_to_time_ms(opts, :timer, :time_ms)
    struct(__MODULE__, opts)
  end
end
