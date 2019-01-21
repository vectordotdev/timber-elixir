defmodule Timber.Events.TemplateRenderEvent do
  @moduledoc ~S"""
  **DEPRECATED**

  This module is deprecated in favor of using `map`s. The next evolution of Timber (2.0)
  no long requires a strict schema and therefore simplifies how users set context:

      Logger.info(fn ->
        message = "Rendered #{template_name} in #{duration_ms}ms"
        event = %{template_rendered: %{name: name, duration_ms: duration_ms}}
        {message, event: event}
      end)

  Please note, you can use the official
  [`:timber_phoenix`](https://github.com/timberio/timber-elixir-phoenix) integration to
  automatically structure this event with metadata.
  """

  @type t :: %__MODULE__{
          name: String.t(),
          time_ms: float
        }

  @enforce_keys [:name, :time_ms]
  defstruct [
    :name,
    :time_ms
  ]

  @doc """
  Message to be used when logging.
  """
  @spec message(t) :: IO.chardata()
  def message(%__MODULE__{name: name, time_ms: time_ms}),
    do: ["Rendered ", ?", name, ?", " in ", Float.to_string(time_ms), "ms"]

  defimpl Timber.Eventable do
    def to_event(event) do
      event = Map.from_struct(event)
      %{template_rendered: event}
    end
  end
end
