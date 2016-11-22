defmodule Timber.Event do

  alias Timber.{Events, Utils}

  @type t ::
    Events.ControllerCallEvent  |
    Events.CustomEvent          |
    Events.ExceptionEvent       |
    Events.HTTPRequestEvent     |
    Events.HTTPResponseEvent    |
    Events.SQLQueryEvent        |
    Events.TemplateRenderEvent

  @doc """
  Presents the event the way it should be encoded. The log ingestion system for Timber
  expects events to be encoded such that their type is the key holding the event
  specific data.
  """
  def event_for_encoding(nil),
    do: nil

  def event_for_encoding(%Events.ControllerCallEvent{} = event),
    do: event_to_map(:controller_call, event)

  def event_for_encoding(%Events.CustomEvent{} = event),
    do: event_to_map(:custom, event)

  def event_for_encoding(%Events.ExceptionEvent{} = event),
    do: event_to_map(:exception, event)

  def event_for_encoding(%Events.HTTPRequestEvent{} = event),
    do: event_to_map(:http_request, event)

  def event_for_encoding(%Events.HTTPResponseEvent{} = event),
    do: event_to_map(:http_response, event)

  def event_for_encoding(%Events.SQLQueryEvent{} = event),
    do: event_to_map(:sql_query, event)

  def event_for_encoding(%Events.TemplateRenderEvent{} = event),
    do: event_to_map(:template_render, event)

  # Converts any struct into a custom event
  def event_for_encoding(%{__struct__: name} = struct) do
    data = Map.from_struct(struct)
    {time_ms, data} = Map.pop(data, :time_ms)

    %{custom: %{
      name: name,
      data: Map.from_struct,
      time_ms: time_ms
    }}
  end

  defp event_to_map(key, event) do
    value =
      event
      |> Map.from_struct()
      |> Map.drop([:description])

    %{key => value}
  end
end
