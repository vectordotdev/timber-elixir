defmodule Timber.Event do
  @moduledoc """
  A common interface for working with structures in the `Timber.Events` namespace.
  """

  alias Timber.Events

  @type t ::
    Events.ControllerCallEvent     |
    Events.CustomEvent             |
    Events.ExceptionEvent          |
    Events.HTTPClientRequestEvent  |
    Events.HTTPClientResponseEvent |
    Events.HTTPServerRequestEvent  |
    Events.HTTPServerResponseEvent |
    Events.SQLQueryEvent           |
    Events.TemplateRenderEvent

  @doc """
  Returns the official Timber type for this event. Used as the JSON map key when
  sending to Timber.
  """
  @spec type(t) :: atom()
  def type(%Events.ControllerCallEvent{}), do: :controller_call
  def type(%Events.CustomEvent{}), do: :custom
  def type(%Events.ExceptionEvent{}), do: :exception
  def type(%Events.HTTPClientRequestEvent{}), do: :http_client_request
  def type(%Events.HTTPClientResponseEvent{}), do: :http_client_response
  def type(%Events.HTTPServerRequestEvent{}), do: :http_server_request
  def type(%Events.HTTPServerResponseEvent{}), do: :http_server_response
  def type(%Events.SQLQueryEvent{}), do: :sql_query
  def type(%Events.TemplateRenderEvent{}), do: :template_render
end