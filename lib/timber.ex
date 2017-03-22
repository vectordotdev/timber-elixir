defmodule Timber do
  @moduledoc """
  The functions in this module are high level convenience functions instended to define
  the broader / public API of the Timber library. It is recommended to use these functions
  instead of their deeper counterparts.
  """

  use Application

  alias Timber.{Context, Contextable}

  @doc """
  Adds a context entry to the stack. See `Timber::Contexts::CustomContext` for examples.
  """
  @spec add_context(Context.context_element) :: :ok
  def add_context(data) do
    current_metadata = Elixir.Logger.metadata()
    current_context = Keyword.get(current_metadata, :timber_context, Context.new())
    context_element = Contextable.to_context(data)
    new_context = Context.add(current_context, context_element)

    Elixir.Logger.metadata([timber_context: new_context])
  end

  @doc """
  Used to time runtime execution. For example, when timing a `Timber.Events.HTTPClientRequestEvent`:

  ```elixir
  timer = Timber.start_timer()
  # .... make request
  time_ms = Timber.duration_ms(timer)
  event = HTTPClientResponseEvent.new(status: 200, time_ms: time_ms)
  message = HTTPClientResponseEvent.message(event)
  Logger.info(message, event: event)
  ```

  """
  defdelegate start_timer, to: Timber.Timer, as: :start

  @doc """
  Captures the duration in fractional milliseconds since the timer was started. See
  `start_timer/0`.
  """
  defdelegate duration_ms(timer), to: Timber.Timer

  @doc false
  def debug(message_fun) do
    Timber.Config.debug_io_device()
    |> debug(message_fun)
  end

  @doc false
  def debug(nil, _message_fun) do
     false
  end

  def debug(io_device, message_fun) when is_function(message_fun) do
    IO.write(io_device, message_fun.())
  end

  @doc false
  # Handles the application callback start/2
  #
  # Starts an empty supervisor in order to comply with callback expectations
  #
  # This is the function that starts up the error logger listener
  #
  def start(_type, _opts) do
    import Supervisor.Spec, warn: false

    children = []

    opts = [strategy: :one_for_one, name: Timber.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
