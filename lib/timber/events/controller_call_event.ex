defmodule Timber.Events.ControllerCallEvent do
  @moduledoc ~S"""
  **DEPRECATED**

  This module is deprecated in favor of using `map`s. The next evolution of Timber (2.0)
  no long requires a strict schema and therefore simplifies how users set context:

      Logger.info(fn ->
        message = "Processing with #{controller}.#{action}/2, Pipelines: #{pipelines}"
        params_json = Timber.encode_json!(params)
        event = %{controller_called: %{
          controller: controller,
          action: action,
          pipelines: pipelines,
          params_json: params_json
        }}
        {message, event: event}
      end)

  Please note, you can use the official
  [`:timber_phoenix`](https://github.com/timberio/timber-elixir-phoenix) integration to
  automatically structure this event with metadata.
  """

  @type t :: %__MODULE__{
          action: String.t(),
          controller: String.t(),
          params_json: String.t() | nil,
          pipelines: String.t() | nil
        }

  @enforce_keys [:action, :controller]
  defstruct [
    :action,
    :controller,
    :params_json,
    :pipelines
  ]

  @params_json_max_bytes 8_192

  @doc """
  Builds a new struct taking care to:

  * Converts `:params` to `:params_json` that satifies the Timber API requirements
  """
  @spec new(Keyword.t()) :: t
  def new(opts) do
    params = Keyword.get(opts, :params)

    params_json =
      if params && map_size(params) != 0 do
        params
        |> Jason.encode_to_iodata!()
        |> Timber.Utils.Logger.truncate_bytes(@params_json_max_bytes)
        |> to_string()
      else
        nil
      end

    new_opts =
      opts
      |> Keyword.delete(:params)
      |> Keyword.put(:params_json, params_json)

    struct!(__MODULE__, new_opts)
  end

  @doc """
  Message to be used when logging.
  """
  @spec message(t) :: IO.chardata()
  def message(%__MODULE__{action: action, controller: controller, pipelines: pipelines}) do
    ["Processing with ", controller, ?., action, ?/, ?2, " Pipelines: ", inspect(pipelines)]
  end

  defimpl Timber.Eventable do
    def to_event(event) do
      event = Map.from_struct(event)
      %{controller_called: event}
    end
  end
end
