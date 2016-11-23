defmodule Timber.Event do
  @moduledoc """
  A common interface for working with Timber events. That is, anything that
  implements the `Timber.Eventable` protocol.
  """

  @type t ::
    Events.ControllerCallEvent  |
    Events.CustomEvent          |
    Events.ExceptionEvent       |
    Events.HTTPRequestEvent     |
    Events.HTTPResponseEvent    |
    Events.SQLQueryEvent        |
    Events.TemplateRenderEvent

  @type message :: IO.chardata
  @type metadata :: [timber_event: Timber.Eventable.t]

  @callback message(t) :: message

  @doc """
  Extracts the message from the event.

  Using custom events? Simple define a `message/1` method or add a `:message` attribute.
  """
  @spec message(Timber.Eventable.t) :: message
  def message(data) do
    event = Timber.Eventable.to_event(data)
    event.__struct__.message(event)
  end

  @doc """
  Convenience method for keying the metadata with `:timber_event`.
  """
  @spec metadata(Timber.Eventable.t) :: metadata
  def metadata(data) do
    [timber_event: data]
  end

  @doc """
  Convenience method for getting the message and metadata in one call.

    ```
    require Logger
    {message, metdata} = Timber.Event.logger_tuple(data)
    Logger.info(message, metdata)
    ```

  This is equivalent to:

    ```
    require Logger
    event = Timber.Eventable.to_event(data)
    message = Timber.Event.message(event)
    Logger.info(message, timber_event: event)
    ```

  In future versions of Elixir, a logger passed function can return this tuple.
  See https://github.com/elixir-lang/elixir/pull/5447. Once available, you'll be
  able to do:

    ```
    # Warning, the below code will not work until the above PR is released!
    require Logger
    Logger.info fn -> Timber.Event.logger_tuple(event) end
    ```

  """
  @spec logger_tuple(Timber.Eventable.t) :: {message, metadata}
  def logger_tuple(data) do
    event = Timber.Eventable.to_event(data)
    {message(event), metadata(event)}
  end
end