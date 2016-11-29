defmodule Timber.Event do
  @moduledoc """
  A common interface for working with Timber events. That is, anything that
  implements the `Timber.Eventable` protocol.
  """

  alias Timber.{Eventable, Events}

  @type t ::
    Events.ControllerCallEvent  |
    Events.CustomEvent          |
    Events.ExceptionEvent       |
    Events.HTTPRequestEvent     |
    Events.HTTPResponseEvent    |
    Events.SQLQueryEvent        |
    Events.TemplateRenderEvent

  @doc """
  Converts the given event to a map in the structure that the Timber API
  expects during ingestion.
  """
  def to_api_map(%Events.ControllerCallEvent{} = event),
    do: %{type: :controller_call, data: Map.from_struct(event)}
  def to_api_map(%Events.CustomEvent{name: name, data: data} = event),
    do: %{type: :custom, name: name, data: data}
  def to_api_map(%Events.ExceptionEvent{} = event),
    do: %{type: :exception, data: Map.from_struct(event)}
  def to_api_map(%Events.HTTPRequestEvent{} = event),
    do: %{type: :http_request, data: Map.from_struct(event)}
  def to_api_map(%Events.HTTPResponseEvent{} = event),
    do: %{type: :http_response, data: Map.from_struct(event)}
  def to_api_map(%Events.SQLQueryEvent{} = event),
    do: %{type: :sql_query, data: Map.from_struct(event)}
  def to_api_map(%Events.TemplateRenderEvent{} = event),
    do: %{type: :template_render, data: Map.from_struct(event)}
  def to_api_map(eventable) do
    eventable
    |> Eventable.to_event()
    |> to_api_map()
  end
end