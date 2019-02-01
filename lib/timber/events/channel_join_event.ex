defmodule Timber.Events.ChannelJoinEvent do
  @deprecated_message """
  The `Timber.Events.ChannelJoinEvent` module is deprecated.

  The next evolution of Timber (2.0) no long requires a strict schema and therefore
  simplifies how users log events.

  To easily migrate, please install the `:timber_phoenix` library:

  https://github.com/timberio/timber-elixir-phoenix
  """

  @moduledoc ~S"""
  **DEPRECATED**

  #{@deprecated_message}
  """

  @type t :: %__MODULE__{
          channel: String.t(),
          topic: String.t(),
          metadata_json: String.t() | nil
        }

  @enforce_keys [:channel, :topic]
  defstruct [
    :channel,
    :topic,
    :metadata_json
  ]

  @doc false
  @deprecated @deprecated_message
  @spec new(Keyword.t()) :: t
  def new(opts) do
    struct!(__MODULE__, opts)
  end

  @doc false
  @deprecated @deprecated_message
  @spec message(t) :: IO.chardata()
  def message(%__MODULE__{channel: channel, topic: topic}) do
    ["Joined channel ", to_string(channel), " with \"", to_string(topic), "\""]
  end

  defimpl Timber.Eventable do
    def to_event(event) do
      event = Map.from_struct(event)
      %{channel_joined: event}
    end
  end
end
