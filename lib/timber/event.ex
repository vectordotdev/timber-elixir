defmodule Timber.Event do
  @moduledoc """
  A common interface for working with Timber events. That is, anything that
  implements the `Timber.Eventable` protocol.
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

  def to_logger_metadata(event) do
    Keyword.put([], Timber.Config.event_key(), event)
  end
end