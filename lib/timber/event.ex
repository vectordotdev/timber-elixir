defmodule Timber.Event do
  @moduledoc """
  A common interface for working with structures in the `Timber.Events` namespace.
  """

  alias Timber.Events
  alias Timber.Utils.Map, as: UtilsMap

  @type t ::
    Events.ChannelJoinEvent    |
    Events.ChannelReceiveEvent |
    Events.ControllerCallEvent |
    Events.CustomEvent         |
    Events.ErrorEvent          |
    Events.HTTPRequestEvent    |
    Events.HTTPResponseEvent   |
    Events.SQLQueryEvent       |
    Events.TemplateRenderEvent

  @doc false
  @spec extract_from_metadata(Keyword.t) :: nil | t
  def extract_from_metadata(metadata) do
    Keyword.get(metadata, Timber.Config.event_key(), nil)
  end

  @doc false
  @spec to_metadata(Timber.Event.t) :: Keyword.t
  def to_metadata(event) do
    Keyword.put([], Timber.Config.event_key(), event)
  end

  @doc false
  @spec to_api_map(t) :: map
  def to_api_map(%Events.CustomEvent{type: type} = event) when is_binary(type) do
    atom_type = String.to_atom(type)

    %{event | type: atom_type}
    |> to_api_map()
  end

  def to_api_map(%Events.CustomEvent{type: type, data: data}) do
    data = normalize_data(data)
    %{custom: %{type => data}}
  end

  def to_api_map(%Events.ControllerCallEvent{} = event) do
    type = type(event)
    map =
      event
      |> normalize_data()
      |> Map.delete(:pipelines)
    %{type => map}
  end

  def to_api_map(event) do
    type = type(event)
    map = normalize_data(event)
    %{type => map}
  end

  defp normalize_data(data) do
    data
    |> UtilsMap.deep_from_struct()
    |> UtilsMap.recursively_drop_blanks()
  end

  @doc """
  Returns the official Timber type for this event. Used as the JSON map key when
  sending to Timber.
  """
  @spec type(t) :: atom()
  def type(%Events.ChannelJoinEvent{}), do: :channel_join
  def type(%Events.ChannelReceiveEvent{}), do: :channel_receive
  def type(%Events.ControllerCallEvent{}), do: :controller_call
  def type(%Events.CustomEvent{}), do: :custom
  def type(%Events.ErrorEvent{}), do: :error
  def type(%Events.HTTPRequestEvent{}), do: :http_request
  def type(%Events.HTTPResponseEvent{}), do: :http_response
  def type(%Events.SQLQueryEvent{}), do: :sql_query
  def type(%Events.TemplateRenderEvent{}), do: :template_render
end