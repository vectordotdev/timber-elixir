defmodule Timber.Contexts.TemplateRenderContext do
  @type t :: %__MODULE__{
    name: String.t,
    time_ms: float
  }

  defstruct [:name, :time_ms]
end
