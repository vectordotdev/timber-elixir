defmodule Timber.Events.TemplateRenderEvent do
  @moduledoc """
  The `TemplateRenderEvent` trackes template rendering within your app.

  Giving you structured insight into template rendering performance.

  The defined structure of this data can be found in the log event JSON schema:
  https://github.com/timberio/log-event-json-schema

  Timber can automatically track template rendering events if you
  use the Phoenix framework and set up `Timber.Phoenix`.
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
end
