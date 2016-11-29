defmodule Timber.Events.CustomEvent do
  @moduledoc """
  Allows for custom events that aren't covered elsewhere.

  Custom events can be used to encode information about events that are central
  to your line of business like receiving credit card payments, saving a draft of a post,
  or changing a user's password.

  ## Fields

    * `type` - (atom, required) This is the type of your event. It should be something unique
      and unchanging. It will be used to identify this event. Example: `:my_event`.
    * `data` - (map, optional) A map of data. This can be anything that implements the
      `Poison.Encoder` protocol. That is, anything that can be JSON encoded.
      Example: `%{key: "value"}`.

  ## Special `data` fields

  These are special fields Timber looks for to enhancement your experience with our interface.
  For example, if `time_ms` is present we'll display it next to the log line.

    * `time_ms` - A fractional float represented the execution time in milliseconds.
      example: `45.6`

  An example:

    Timber.Events.CustomEvent.new(type: :payment_rejected, data: %{time_ms: 45.6})

  ## Examples

  Please see `Timber.Eventable` for examples on using custom events.

  """

  @type t :: %__MODULE__{
    type: atom(),
    data: map() | nil
  }

  @enforce_keys [:type]
  defstruct [
    :data,
    :type
  ]

  @doc ~S"""
  Creates a new custom event. Takes any of the fields described in the module docs as keys.
  """
  @spec new(Keyword.t) :: t
  def new(opts) do
    struct(__MODULE__, opts)
  end
end
