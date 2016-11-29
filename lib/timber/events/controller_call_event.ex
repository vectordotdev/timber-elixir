defmodule Timber.Events.ControllerCallEvent do
  @moduledoc """
  Represents a controller being called
  """

  @type t :: %__MODULE__{
    action: String.t | nil,
    controller: String.t | nil,
  }

  defstruct [
    :action,
    :controller
  ]

  @spec new(Keyword.t) :: t
  def new(opts) do
    struct(__MODULE__, opts)
  end

  @spec message(t) :: IO.chardata
  def message(%__MODULE__{action: action, controller: controller}) do
    ["Processing by ", controller, ?., action]
  end
end
