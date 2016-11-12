defmodule Timber.Events.CustomEvent do
  @moduledoc """
  Allows for custom events that aren't covered elsewhere

  Custom events can be used to encode information about events that are central
  to your line of business like receiving credit card payments, adding products
  to a card, saving a draft of a post, or ghanging a user's password.

  Custom events take a `name` and a map of `data`. You can choose either strings
  or atoms as keys, and values can contain nested maps. The only requirement is
  that is that you don't use tuples as this will cause an encoder issue.

  The resulting event can be passed to `Logger` in the `:timber_event` key of
  the metadata. See the documentation for `new/1`.
  """

  @type t :: %__MODULE__{
    name: String.t | nil,
    data: map | nil
  }

  defstruct [
    :data,
    :name
  ]

  @doc ~S"""
  Creates a new custom event

  ```
  event_data = %{customer_id: "xiaus1934", amount: 1900, currency: "USD"}
  event = CustomEvent.new(name: :payment_received, data: event_data)

  Logger.info("Received payment", timber_event: event)
  ```

  Note: You cannot use tuples in your data structure. Trying to include them
  will cause an encoding error.
  """
  @spec new(Keyword.t) :: t
  def new(opts) do
    struct(__MODULE__, opts)
  end
end
