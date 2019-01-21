defmodule Timber.Events.ChannelReceiveEvent do
  @moduledoc ~S"""
  **DEPRECATED**

  This module is deprecated in favor of using `map`s. The next evolution of Timber (2.0)
  no long requires a strict schema and therefore simplifies how users set context:

      Logger.info(fn ->
        message = "Received #{event} on #{topic} to #{channel}"
        event = %{channel_event_received: %{channel: channel, topic: topic, event: event}}
        {message, event: event}
      end)

  Please note, you can use the official
  [`:timber_phoenix`](https://github.com/timberio/timber-elixir-phoenix) integration to
  automatically structure this event with metadata.
  """

  @type t :: %__MODULE__{
          channel: String.t(),
          topic: String.t(),
          event: String.t(),
          metadata_json: String.t() | nil
        }

  @enforce_keys [:channel, :topic, :event]
  defstruct [
    :channel,
    :topic,
    :event,
    :metadata_json
  ]

  @metadata_json_byte_limit 8_192

  @doc """
  Builds a new struct taking care to:

  * Converts `:params` to `:params_json` that satifies the Timber API requirements
  """
  @spec new(Keyword.t()) :: t
  def new(opts) do
    metadata_json =
      case Keyword.get(opts, :metadata_json, nil) do
        nil ->
          nil

        metadata_json ->
          metadata_json
          |> Timber.Utils.Logger.truncate_bytes(@metadata_json_byte_limit)
          |> to_string()
      end

    new_opts = Keyword.put(opts, :metadata_json, metadata_json)

    struct!(__MODULE__, new_opts)
  end

  @doc """
  Message to be used when logging.
  """
  @spec message(t) :: IO.chardata()
  def message(%__MODULE__{channel: channel, topic: topic, event: event}) do
    ["Received ", to_string(event), " on \"", to_string(topic), "\" to ", to_string(channel)]
  end

  defimpl Timber.Eventable do
    def to_event(event) do
      event = Map.from_struct(event)
      %{channel_event_received: event}
    end
  end
end
