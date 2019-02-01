defmodule Timber.Events.ControllerCallEvent do
  @deprecated_message ~S"""
  The `Timber.Events.ControllerCallEvent` module is deprecated in favor of using `map`s.

  The next evolution of Timber (2.0) no long requires a strict schema and therefore
  simplifies how users log events.

  To easily migrate, please install the `:timber_phoenix` library:

  https://github.com/timberio/timber-elixir-phoenix
  """

  @moduledoc ~S"""
  **DEPRECATED**

  #{@deprecated_message}
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

  @doc false
  @deprecated @deprecated_message
  @spec new(Keyword.t()) :: t
  def new(opts) do
    params = Keyword.get(opts, :params)

    params_json =
      if params && map_size(params) != 0 do
        params
        |> Timber.try_encode_to_json()
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

  @doc false
  @deprecated @deprecated_message
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
