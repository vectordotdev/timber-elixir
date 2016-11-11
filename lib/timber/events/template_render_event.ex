defmodule Timber.Events.TemplateRenderEvent do
  @moduledoc """
  Tracks the time to render a template
  """

  @type t :: %__MODULE__{
    name: String.t | nil,
    description: IO.chardata | nil,
    time_ms: float | nil,
  }

  defstruct [
    :description,
    :name,
    :time_ms
  ]

  @spec new(Keyword.t) :: t
  def new(opts) do
    event = struct(__MODULE__, opts)
    time = Float.to_string(event.time_ms)
    description = ["Rendered ", ?", event.name, ?", " in ", time, "ms"]

    %__MODULE__{ event | description: description }
  end
end
