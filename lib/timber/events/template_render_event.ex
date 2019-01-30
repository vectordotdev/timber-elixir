defmodule Timber.Events.TemplateRenderEvent do
  @deprecated_message ~S"""
  The `Timber.Events.TemplateRenderEvent` module is deprecated.

  The next evolution of Timber (2.0) no long requires a strict schema and therefore
  simplifies how users log events.

  To easily migrate, please install the `:timber_phoenix` library:

  https://github.com/timberio/timber-elixir-phoenix
  """

  @moduledoc ~S"""
  **DEPRECATED**

  #{@deprecated_message}
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

  @doc false
  @deprecated @deprecated_message
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
