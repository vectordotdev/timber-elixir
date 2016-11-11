defmodule Timber.Events.ControllerCallEvent do
  @moduledoc """
  Represents a controller being called
  """

  @type t :: %__MODULE__{
    action: String.t | nil,
    controller: String.t | nil,
    description: IO.chardata | nil
  }

  defstruct [
    :action,
    :controller,
    :description
  ]

  @spec new(Keyword.t) :: t
  def new(opts) do
    event = struct(__MODULE__, opts)
    description = ["Processing by ", event.controller, ?., event.action]

    %__MODULE__{ event | description: description }
  end
end
