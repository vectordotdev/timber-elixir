defmodule Timber.Events.ControllerCallEvent do
  @moduledoc """
  The `ControllerCallEvent` represents a controller being called during the HTTP request
  cycle.
  """

  @type t :: %__MODULE__{
    action: String.t | nil,
    controller: String.t | nil,
  }

  @enforce_keys [:action, :controller]
  defstruct [
    :action,
    :controller
  ]

  @doc """
  Message to be used when logging.
  """
  @spec message(t) :: IO.chardata
  def message(%__MODULE__{action: action, controller: controller}) do
    ["Processing by ", controller, ?., action]
  end
end
