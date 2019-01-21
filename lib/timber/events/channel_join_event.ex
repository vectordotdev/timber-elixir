defmodule Timber.Events.ChannelJoinEvent do
  @moduledoc ~S"""
  **DEPRECATED**

  This module is deprecated in favor of using `map`s. The next evolution of Timber (2.0)
  no long requires a strict schema and therefore simplifies how users set context:

      Logger.info(fn ->
        message = "Joined channel #{channel_name} with #{topic}"
        event = %{channel_joined: %{channel: channel, topic: topic}}
        {message, event: event}
      end)

  Please note, you can use the official
  [`:timber_phoenix`](https://github.com/timberio/timber-elixir-phoenix) integration to
  automatically structure this event with metadata.
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

  @metadata_json_byte_limit 8_192

  @doc """
  Builds a new struct taking care to:

  * Converts `:params` to `:params_json` that satifies the Timber API requirements
  """
  @deprecated """
  The Timber service no longer requires a strict schema and therefore logging events
  no long requires structs:

  event = %{channel_joined: %{channel: "channel_name"}}
  Logger.info("Channel joined", event: event)
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
