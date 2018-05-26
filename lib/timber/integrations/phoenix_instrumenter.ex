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

  ## Ignoring Controller Actions for Instrumentation

  If you have specific controller actions that you don't want to be instrumented,
  you can add them to the instrumentation blacklist. For example, if your application
  provides a health controller for external applications, you may want to stop
  instrumentation on that controller's actions to reduce noise.

  The `:controller_actions_blacklist` configuration key can be used to control which
  controller actions to suppress instrumentation for. It takes a list of two-element
  tuples. The first element is the controller name, and the second element is the
  action.


  As an example, here's how we would prevent instrumentation of the `check` action in
  `TimberClientAPI.HealthController`:

  ```elixir
  config :timber, Timber.Integrations.PhoenixInstrumenter,
    controller_actions_blacklist: [
      {TimberClientAPI.HealthController, :check}
    ]
  ```

  Now, when Phoenix calls `check/2` on the `TimberClientAPI.HealthController` module,
  no log lines will be produced!

  _Note_: If you're on a version of Phoenix prior to 1.3, you will still see logs for
  render events even if the controller is blacklisted.
  """

  require Logger

  alias Timber.Event
  alias Timber.Events.ChannelJoinEvent
  alias Timber.Events.ChannelReceiveEvent
  alias Timber.Events.ControllerCallEvent
  alias Timber.Events.TemplateRenderEvent

  @typep controller :: module
  @typep action :: atom
  @typep controller_action :: {controller, action}
  @typep unparsed_blacklist :: [controller_action]
  @typep parsed_blacklist :: MapSet.t(controller_action)

  @doc """
  Adds a controller action to the blacklist

  This function will update the blacklist of controller actions, following the
  same conventions as the blacklist described in the application configuration.

  The `controller` should be the qualified name of the Phoenix controller's
  Elixir module (e.g., `TimberClientAPI.OrganizationController`).

  The `action` should be the name of the action (e.g., `index`).
  """
  @spec add_controller_action_to_blacklist(controller, action) :: :ok
  def add_controller_action_to_blacklist(controller, action) do
    controller_action = {controller, action}
    blacklist = get_parsed_blacklist()
    new_blacklist = MapSet.put(blacklist, controller_action)
    put_parsed_blacklist(new_blacklist)
  end

  @doc """
  Removes controller action from the blacklist

  This function will update the blacklist of controller actions, following the
  same conventions as the blacklist described in the application configuration.

  The `controller` should be the qualified name of the Phoenix controller's
  Elixir module (e.g., `TimberClientAPI.OrganizationController`).

  The `action` should be the name of the action (e.g., `index`).
  """
  @spec remove_controller_action_from_blacklist(controller, action) :: :ok
  def remove_controller_action_from_blacklist(controller, action) do
    controller_action = {controller, action}
    blacklist = get_parsed_blacklist()
    new_blacklist = MapSet.delete(blacklist, controller_action)
    put_parsed_blacklist(new_blacklist)
  end

  @doc false
  @spec controller_action_blacklisted?({controller, action}, parsed_blacklist) :: boolean
  def controller_action_blacklisted?(controller_action, blacklist) do
    MapSet.member?(blacklist, controller_action)
  end

  @doc false
  @spec get_parsed_blacklist() :: parsed_blacklist
  # The parsed version of the controller actions blacklist is stored in the
  # application environment at
  # [:timber, Timber.Integrations.PhoenixInstrumenter, :parsed_controller_actions_blacklist].
  # This function fetches that value, returning an empty MapSet if the environment
  # entry does not exist
  def get_parsed_blacklist() do
    opts = Application.get_env(:timber, __MODULE__, [])
    Keyword.get(opts, :parsed_controller_actions_blacklist, MapSet.new())
  end

  @doc false
  @spec put_parsed_blacklist(parsed_blacklist) :: :ok
  def put_parsed_blacklist(parsed_blacklist) do
    opts = Application.get_env(:timber, __MODULE__, [])
    updated_opts = Keyword.put(opts, :parsed_controller_actions_blacklist, parsed_blacklist)
    Application.put_env(:timber, __MODULE__, updated_opts)
  end

  @doc false
  @spec get_unparsed_blacklist() :: unparsed_blacklist
  # The controller actions blacklist is stored in the application environment at
  # [:timber, Timber.Integrations.PhoenixInstrumenter, :controller_actions_blacklist].
  #
  # This function fetches that list, returning an empty list if the environment entry
  # does not exist.
  def get_unparsed_blacklist() do
    opts = Application.get_env(:timber, __MODULE__, [])
    Keyword.get(opts, :controller_actions_blacklist, [])
  end

  @doc false
  @spec parse_blacklist(unparsed_blacklist) :: parsed_blacklist
  # Parses a controller action blacklist into a MapSet
  def parse_blacklist(blacklist) do
    MapSet.new(blacklist)
  end

  #
  # Channels
  #

  @doc false
  @spec phoenix_channel_join(:start, compile_metadata :: map, runtime_metadata :: map) :: :ok
  @spec phoenix_channel_join(
          :stop,
          time_diff_native :: non_neg_integer,
          result_of_before_callback :: :ok
        ) :: :ok
  def phoenix_channel_join(:start, _compile, %{socket: socket, params: params}) do
    # Any value using try_atom_to_string handles nil values since they are not always present.
    log_level = get_log_level(:info)
    channel = try_atom_to_string(socket.channel)
    topic = socket.topic
    transport = try_atom_to_string(socket.transport)
    serializer = try_atom_to_string(socket.serializer)
    protocol_version = if Map.has_key?(socket, :vsn), do: socket.vsn, else: nil
    filtered_params = filter_params(params)

    metadata = %{
      transport: transport,
      serializer: serializer,
      protocol_version: protocol_version,
      params: filtered_params
    }

    metadata_json =
      case Timber.Utils.JSON.encode_to_iodata(metadata) do
        {:ok, json} -> IO.iodata_to_binary(json)
        {:error, _error} -> nil
      end

    event =
      ChannelJoinEvent.new(
        channel: channel,
        topic: topic,
        metadata_json: metadata_json
      )

    message = ChannelJoinEvent.message(event)
    metadata = Event.to_metadata(event)

    Logger.log(log_level, message, metadata)
  end

  def phoenix_channel_join(:stop, _compile, :ok),
    do: :ok

  def phoenix_channel_receive(:start, _compile, meta) do
    %{socket: socket, params: params, event: event} = meta

    log_level = get_log_level(:info)
    channel = try_atom_to_string(socket.channel)
    topic = socket.topic
    transport = try_atom_to_string(socket.transport)
    filtered_params = filter_params(params)

    metadata = %{
      transport: transport,
      params: filtered_params
    }

    metadata_json =
      case Timber.Utils.JSON.encode_to_iodata(metadata) do
        {:ok, json} -> IO.iodata_to_binary(json)
        {:error, _error} -> nil
      end

    event =
      ChannelReceiveEvent.new(
        channel: channel,
        topic: topic,
        event: event,
        metadata_json: metadata_json
      )

    message = ChannelReceiveEvent.message(event)
    metadata = Event.to_metadata(event)

    Logger.log(log_level, message, metadata)
  end

  def phoenix_channel_receive(:stop, _compile, :ok),
    do: :ok

  #
  # Controllers
  #

  @doc false
  @spec phoenix_controller_call(:start, compile_metadata :: map, runtime_metadata :: map) :: :ok
  @spec phoenix_controller_call(
          :stop,
          time_diff_native :: non_neg_integer,
          result_of_before_callback :: :ok
        ) :: :ok
  def phoenix_controller_call(:start, _, %{conn: conn}) do
    controller_actions_blacklist = get_parsed_blacklist()

    controller = Phoenix.Controller.controller_module(conn)
    action = Phoenix.Controller.action_name(conn)

    if !controller_action_blacklisted?({controller, action}, controller_actions_blacklist) do
      "Elixir." <> controller_name = to_string(controller)
      action_name = to_string(action)
      log_level = get_log_level(:info)
      # Phoenix actions are always 2 arity function
      params = filter_params(conn.params)
      pipelines = conn.private[:phoenix_pipelines]

      event =
        ControllerCallEvent.new(
          action: action_name,
          controller: controller_name,
          params: params,
          pipelines: pipelines
        )

      message = ControllerCallEvent.message(event)
      metadata = Event.to_metadata(event)

      Logger.log(log_level, message, metadata)
    end

    :ok
  end

  def phoenix_controller_call(:stop, _time_diff, :ok) do
    :ok
  end

  @doc false
  @spec phoenix_controller_render(:start, map, map) :: :ok
  @spec phoenix_controller_render(:stop, non_neg_integer, :ok | {:ok, atom, String.t()} | false) ::
          :ok
  def phoenix_controller_render(:start, _compile_metadata, %{template: template_name, conn: conn}) do
    has_controller? = Map.has_key?(conn.private, :phoenix_controller)
    has_action? = Map.has_key?(conn.private, :phoenix_action)

    if has_controller? and has_action? do
      render_check(conn, template_name)
    else
      handle_render_blacklist(false, template_name)
    end
  end

  def phoenix_controller_render(:start, _compile_metadata, %{template: template_name}) do
    handle_render_blacklist(false, template_name)
  end

  def phoenix_controller_render(:start, _, _) do
    # Absolute fall-through. This catch-all is provided for any scenario that
    # has not been otherwise accounted for. It sets the return to :ok which will
    # result in no log being produced
    :ok
  end

  def phoenix_controller_render(:stop, _time_diff, :ok) do
    # The default return for phoenix_controller_render(:start, _, _) is :ok
    # If the parameters passed are [:stop, _, :ok], it means that the :start
    # phase failed and Phoenix is giving us :ok as the default
    #
    # In this case, we do nothing
    :ok
  end

  def phoenix_controller_render(:stop, _time_diff, false) do
    # The render event should not be logged
    :ok
  end

  def phoenix_controller_render(:stop, time_diff, {:ok, log_level, template_name}) do
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
    metadata = Event.to_metadata(event)

    Logger.log(log_level, message, metadata)

    :ok
  end

  #
  # Utility
  #

  @spec get_log_level(atom) :: atom
  defp get_log_level(default) do
    Timber.Config.phoenix_instrumentation_level(default)
  end

  # Takes a conn from a render event that definitely has a controller and action
  # and returns an appropriate response for the phoenix_controller_render :start event
  defp render_check(conn, template_name) do
    controller_actions_blacklist = get_parsed_blacklist()

    controller = Phoenix.Controller.controller_module(conn)
    action = Phoenix.Controller.action_name(conn)

    blacklisted? =
      controller_action_blacklisted?({controller, action}, controller_actions_blacklist)

    handle_render_blacklist(blacklisted?, template_name)
  end

  # Takes a boolean value that determines whether the render call is blacklisted
  # and returns an appropirate response for the phoenix_controller_render :start event
  defp handle_render_blacklist(true, _) do
    false
  end

  defp handle_render_blacklist(false, template_name) do
    log_level = get_log_level(:info)
    {:ok, log_level, template_name}
  end

  defp filter_params(%{__struct__: :"Elixir.Plug.Conn.Unfetched"}) do
    %{}
  end

  defp filter_params(params) when is_map(params) do
    params
    |> filter_values()
    |> Enum.into(%{})
  end

  defp filter_params(params) when is_list(params) do
    filtered_params = filter_values(params)

    # In practice, it's actually improbable that the payload
    # will be a Keyword list, but we handle this as a safeguard
    if Keyword.keyword?(filtered_params) do
      Enum.into(filtered_params, %{})
    else
      filtered_params
    end
  end

  # Non-structured type, take as-is
  defp filter_params(params) do
    filter_values(params)
  end

  defp filter_values(params) do
    if function_exported?(Phoenix.Logger, :filter_values, 1) do
      Phoenix.Logger.filter_values(params)
    else
      params
    end
  end

  defp try_atom_to_string(atom) when is_atom(atom) do
    Atom.to_string(atom)
  end

  defp try_atom_to_string(_atom) do
    nil
  end
end
