defmodule Timber.Events.TemplateRenderEvent do
  @moduledoc """
  Tracks the time to render a template.

  Timber can automatically track template rendering events if you
  use the Phoenix framework and setup the `Timber.PhoenixInstrumenter`.
  """

  @type t :: %__MODULE__{
    name: String.t | nil,
    time_ms: float | nil,
  }

  defstruct [
    :name,
    :time_ms
  ]

  @spec new(Keyword.t) :: t
  def new(opts) do
    struct(__MODULE__, opts)
  end

  @spec message(t) :: IO.chardata
  def message(%__MODULE__{name: name, time_ms: time_ms}),
    do: ["Rendered ", ?", name, ?", " in ", Float.to_string(time_ms), "ms"]
end
