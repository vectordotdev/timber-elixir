defmodule Timber.Contexts.TemplateRenderContext do
  @moduledoc """
  Tracks the time to render a template
  """

  @type t :: %__MODULE__{
    name: String.t,
    time_ms: float
  }

  defstruct [:name, :time_ms]
end
