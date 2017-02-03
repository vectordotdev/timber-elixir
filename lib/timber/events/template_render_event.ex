defmodule Timber.Events.TemplateRenderEvent do
  @moduledoc """
  The `TemplateRenderEvent` trackes template rendering within your app. Giving you structured
  insight into template rendering performance.

  Timber can automatically track template rendering events if you
  use the Phoenix framework and setup the `Timber.Integrations.PhoenixInstrumenter`.
  """

  @type t :: %__MODULE__{
    name: String.t | nil,
    time_ms: float | nil,
  }

  @enforce_keys [:name, :time_ms]
  defstruct [
    :name,
    :time_ms
  ]

  @doc """
  Message to be used when logging.
  """
  @spec message(t) :: IO.chardata
  def message(%__MODULE__{name: name, time_ms: time_ms}),
    do: ["Rendered ", ?", name, ?", " in ", Float.to_string(time_ms), "ms"]
end
