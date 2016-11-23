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
    iex> event = %{_name: :payment_failed, _time_ms: 45.6, customer_id: "xiaus1934", amount: 1900, currency: "USD"}
    iex> Logger.info("Payment failed", timber_event: event)

  Note that `_name` and `_time_ms` are optional. The above adheres to Timber's no lock-in /
  no code debt promise. But if you're going to log events throughout your app, we recommend doing
  so with more structure:

    iex> require Logger
    iex> timer = Timber.Timer.start() # optional
    iex> # ... code to time ...
    iex> event_data = %{customer_id: "xiaus1934", amount: 1900, currency: "USD"}
    iex> event = Timber.event(name: :payment_failed, data: event_data, timer: timer)
    iex> Logger.info("Payment failed", timber_event: event)

  Alternatively, if you're like us at Timber, you'll want to define structures for each event,
  similar to exceptions:

    iex> require Logger
    iex> defmodule PaymentFailedEvent do
    iex>   defstruct [:customer_id, :amount, :currency, :_time_ms]
    iex> end
    iex> event = %PaymentFailedEvent{customer_id: "xiaus1934", amount: 1900, currency: "USD", _time_ms: 45.6}
    iex> Logger.info("Payment failed", timber_event: event)

  `PaymentReceived`, will be used as the event name unless a `_name` attribute is supplied. Note
  that `Event` suffixes are removed.
  """

  alias Timber.{Timer, Utils}

  @type t :: %__MODULE__{
    name: String.t,
    data: map() | nil,
    time_ms: float() | nil
  }

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
  - `:timer` - The timer returned when calling `Timber.Timer.start()`.
  """
  def new(opts) do
    timer = Keyword.get(opts, :timer)
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
end
