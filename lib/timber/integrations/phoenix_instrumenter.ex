defmodule Timber.Integrations.PhoenixInstrumenter do
  @moduledoc """
  Handles instrumentation of `Phoenix.Endpoint`.

  This module is designed to log events when Phoenix calls a controller or
  renders a template. It hooks into the instrumentation tools built into
  Phoenix. Because of this, you will have to trigger a Phoenix recompile
  in order for the instrumentation to take effect.

  ## Adding Instrumentation

  Phoenix instrumenetation is controlled through the configuration for your
  Phoenix endpoint module, typically named along the lines of `MyApp.Endpoint`.
  This module will be configured in `config/config.exs` similar to the following:

  ```
  config :my_app, MyApp.Endpoint,
    http: [port: 4001],
    root: Path.dirname(__DIR__),
    pubsub: [name: MyApp.PubSub,
              adapter: Phoenix.PubSub.PG2]
  ```

  You will need to add an `:instrumenters` key to this configuration with
  a value of `[Timber.Integrations.PhoenixInstrumenter]`. This would update the configuration
  to something like the following:


  ```
  config :my_app, MyApp.Endpoint,
    http: [port: 4001],
    root: Path.dirname(__DIR__),
    instrumenters: [Timber.Integrations.PhoenixInstrumenter],
    pubsub: [name: MyApp.PubSub,
              adapter: Phoenix.PubSub.PG2]
  ```

  In order for this to take affect locally, you will need to recompile Phoenix using
  the command `mix deps.compile phoenix`. By default, Timber will log calls to controllers
  and template renders at the `:info` level. You can change this by adding an additional
  configuration line:

  ```
  config :timber, :instrumentation_level, :debug
  ```

  If you're currently displaying logs at the `:debug` level, you will also see that
  Phoenix has built-in logging already at this level. The Phoenix logger will not emit
  Timber events, so you can turn it off to stop the duplicate output. The Phoenix logger
  is controlled through the `MyApp.Web` module. Look for a definition block like the
  following:

  ```
  def controller do
    quote do
      use Phoenix.Controller
    end
  end
  ```

  You will want to modify this to the following

  ```
  def controller do
    quote do
      use Phoenix.Controller, log: false
    end
  end
  ```
  """

  require Logger

  alias Timber.Events.ControllerCallEvent
  alias Timber.Events.TemplateRenderEvent

  @doc false
  @spec phoenix_controller_call(:start | :stop, map | non_neg_integer, map | :ok) :: :ok
  def phoenix_controller_call(:start, %{module: module}, %{conn: conn}) do
    log_level = get_log_level(:info)

    controller = inspect(module)
    action_name =
      conn
      |> Phoenix.Controller.action_name()
      |> Atom.to_string()

    # Phoenix actions are always 2 arity function
    params = params(conn.params)
    pipelines = conn.private[:phoenix_pipelines]

    event = ControllerCallEvent.new(
      action: action_name,
      controller: controller,
      params: params,
      pipelines: pipelines
    )

    message = ControllerCallEvent.message(event)
    metadata = Timber.Utils.Logger.event_to_metadata(event)

    Logger.log(log_level, message, metadata)

    :ok
  end

  def phoenix_controller_call(:stop, _time_diff, :ok) do
    :ok
  end

  @doc false
  @spec phoenix_controller_render(:start | :stop, map | non_neg_integer, map | :ok) :: :ok
  def phoenix_controller_render(:start, _compile_metadata, %{template: template_name}) do
    {:ok, template_name}
  end

  def phoenix_controller_render(:stop, time_diff, {:ok, template_name}) do
    log_level = get_log_level(:info)

    # This comes in as native time but is expected to be a float representing
    # milliseconds
    time_ms =
      time_diff
      |> System.convert_time_unit(:native, :milliseconds)
      |> :erlang.float()

    event = %TemplateRenderEvent{
      name: template_name,
      time_ms: time_ms
    }

    message = TemplateRenderEvent.message(event)
    metadata = Timber.Utils.Logger.event_to_metadata(event)

    Logger.log(log_level, message, metadata)

    :ok
  end

  @spec get_log_level(atom) :: atom
  defp get_log_level(default) do
    Timber.Config.phoenix_instrumentation_level(default)
  end

  defp params(%{__struct__: :"Elixir.Plug.Conn.Unfetched"}), do: %{}

  defp params(params) when is_list(params) or is_map(params) do
    params
    |> Phoenix.Logger.filter_values()
    |> Enum.into(%{})
  end

  # Unknown type, convert to a blank map for now
  defp params(_params), do: %{}
end
