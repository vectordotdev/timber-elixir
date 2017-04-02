defmodule Timber.Events.ControllerCallEvent do
  @moduledoc """
  The `ControllerCallEvent` represents a controller being called during the HTTP request
  cycle.
  """

  @type t :: %__MODULE__{
    action: String.t,
    controller: String.t,
    params_json: String.t | nil,
  }

  @enforce_keys [:action, :controller]
  defstruct [
    :action,
    :controller,
    :params_json,
    :pipelines
  ]

  @params_json_limit 5_000

  @doc """
  Builds a new struct taking care to:

  * Converts `:params` to `:params_json` that satifies the Timber API requirements
  """
  @spec new(Keyword.t) :: t
  def new(opts) do
    params = Keyword.get(opts, :params)
    params_json =
      if params && params != %{} do
        params
        |> Timber.Utils.JSON.encode!()
        |> Timber.Utils.Logger.truncate(@params_json_limit)
        |> to_string()
      else
        nil
      end

    %__MODULE__{
      action: Keyword.get(opts, :action),
      controller: Keyword.get(opts, :controller),
      params_json: params_json,
      pipelines: Keyword.get(opts, :pipelines)
    }
  end

  @doc """
  Message to be used when logging.
  """
  @spec message(t) :: IO.chardata
  def message(%__MODULE__{action: action, controller: controller, pipelines: pipelines}) do
    ["Processing with ", controller, ?., action, ?/, ?2, " Pipelines: ", inspect(pipelines)]
  end

  @doc """
  Converts the struct into a map that the Timber API expects. This is the data
  that is sent to the Timber API.
  """
  @spec to_api_map(t) :: map
  def to_api_map(%__MODULE__{action: action, controller: controller, params_json: params_json}) do
    %{action: action, controller: controller, params_json: params_json}
  end
end
