defmodule Timber do
  @moduledoc """
  The functions in this module work by modifying the Logger metadata store which
  is unique to every BEAM process. This is convenient in many ways. First and
  foremost, it does not require you to manually manage the metadata. Second,
  because we conform to the standard Logger principles, you can utilize Timber
  alongside other Logger backends without issue. Timber prefixes its contextual
  metadata keys so as not to interfere with other systems.

  ## The Context Stack
  """

  use Application

  alias Timber.{Context, Contextable}

  @doc """
  Adds a context entry to the stack. See `Timber::Contexts::CustomContext` for examples.
  """
  @spec add_context(Context.context_data) :: :ok
  def add_context(data) do
    current_metadata = Elixir.Logger.metadata()
    current_context = Keyword.get(current_metadata, :timber_context, Context.new())
    context_element = Contextable.to_context(data)
    new_context = Context.add_context(current_context, context_element)

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
  # Handles the application callback start/2
  #
  # Starts an empty supervisor in order to comply with callback expectations
  #
  # This is the function that starts up the error logger listener
  #
  def start(_type, _opts) do
    import Supervisor.Spec, warn: false

    if Timber.Config.capture_errors?() do
      :error_logger.add_report_handler(Timber.Integrations.ErrorLogger)
    end

    if Timber.Config.disable_tty?() do
      :error_logger.tty(false)
    end

    http_client = Timber.Transports.HTTP.get_http_client()
    children =
      if http_client do
        [worker(http_client, [])]
      else
        []
      end

    opts = [strategy: :one_for_one, name: Timber.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
