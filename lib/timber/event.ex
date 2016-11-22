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
  def event_for_encoding(nil) do
    nil
  end

  def event_for_encoding(event) do
    key = key_for_event(event)
    value =
      event
      |> Map.from_struct()
      |> Map.drop([:description])
      |> Utils.drop_nil_values()

    %{
      key => value
    }
  end

  def key_for_event(%Events.ControllerCallEvent{}), do: :controller_call
  def key_for_event(%Events.CustomEvent{}), do: :custom
  def key_for_event(%Events.ExceptionEvent{}), do: :exception
  def key_for_event(%Events.HTTPRequestEvent{}), do: :http_request
  def key_for_event(%Events.HTTPResponseEvent{}), do: :http_response
  def key_for_event(%Events.SQLQueryEvent{}), do: :sql_query
  def key_for_event(%Events.TemplateRenderEvent{}), do: :template_render
end
