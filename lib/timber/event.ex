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
  Easily get the message and metadata in one call.

    iex> require Logger
    iex> {message, metdata} = Timber.Event.logger_tuple(event)
    iex> Logger.info(message, metdata)

  In future versions of Elixir, a logger passed function can return this tuple.
  See https://github.com/elixir-lang/elixir/pull/5447. Once available, you'll be
  able to do:

    iex> # Warning, the below code will not work until the above PR is released!
    iex> require Logger
    iex> Logger.info fn -> Timber.Event.logger_tuple(event) end

  """
  @spec logger_tuple(Timber.Eventable.t) :: {message, metadata}
  def logger_tuple(data) do
    event = Timber.Eventable.to_event(data)
    {message(event), metadata(event)}
  end
end