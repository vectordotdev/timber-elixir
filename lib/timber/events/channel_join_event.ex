defmodule Timber.Events.ChannelJoinEvent do
  @moduledoc """
  The `ChannelJoinEvent` represents a web socket channel topic being joined.

  The defined structure of this data can be found in the log event JSON schema:
  https://github.com/timberio/log-event-json-schema
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
end
