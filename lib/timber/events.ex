defmodule Timber.Events do
  @moduledoc """
  A top-level namespace that holds all Timber events. Each event is a formal defininition
  of various popular events used in Elixir logging. Most of these events are logged for
  you through our integrations (`Timber.Integrations`), but you can define your own custom
  events (`Timber.Events.CustomEvent`) to extend beyond the basic events Timber provides.

  We recommend reviewing the docs for both `Timber.Integrations` as well as
  `Timber.Events.CustomEvent` to understand how events are logged and how you can log them
  yourself.
  """
end
