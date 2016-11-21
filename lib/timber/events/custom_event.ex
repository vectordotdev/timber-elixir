defmodule Timber.Events.CustomEvent do
  @moduledoc """
  Allows for custom events that aren't covered elsewhere.

  Custom events can be used to encode information about events that are central
  to your line of business like receiving credit card payments, adding products
  to a card, saving a draft of a post, or changing a user's password.

  Custom events take a `name` and a map of `data`. You can choose either strings
  or atoms as keys, and values can contain nested maps. The only requirement is
  that is that you don't use tuples as this will cause an encoder issue.

  The resulting event can be passed to `Logger` in the `:timber_event` key of
  the metadata. See the documentation for `new/1`.
  """

  alias Timber.Timer

  @type t :: %__MODULE__{
    name: String.t,
    data: map | nil,
    time_ms: float() | nil
  }

  @enforce_keys [:name]
  defstruct [
    :data,
    :name,
    :time_ms
  ]

  @doc ~S"""
  Creates a new custom event

  Note: You cannot use tuples in your data structure. Trying to include them
  will cause an encoding error.

  ## Examples

  Basic example:

    iex> require Logger
    iex> event_data = %{customer_id: "xiaus1934", amount: 1900, currency: "USD"}
    iex> event = Timber.event(name: :payment_received, data: event_data)
    iex> Logger.info("Received payment", timber_event: event)

  With timing:

    iex> require Logger
    iex> timer = Timber.start_timing()3
    iex> # ... code to time ...
    iex> event_data = %{customer_id: "xiaus1934", amount: 1900, currency: "USD"}
    iex> event = CustomEvent.new(name: :payment_received, data: event_data, timer: timer)
    iex> Logger.info("Received payment", timber_event: event)

  """
  def new(opts) do
    timer = Keyword.get(opts, :timer)
    new_opts =
      if timer do
        time_ms = Timer.duration_ms(timer)
        opts
        |> Keyword.delete(:timer)
        |> Keyword.put(:time_ms, time_ms)
      else
        opts
      end

    struct(__MODULE__, new_opts)
  end
end
