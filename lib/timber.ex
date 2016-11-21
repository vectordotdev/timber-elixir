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

  alias Timber.{Context, Events}

  @doc """
  Adds a context entry to the stack
  """
  @spec add_context(Context.context_data) :: :ok
  def add_context(data) do
    current_metadata = Elixir.Logger.metadata()
    current_context = Keyword.get(current_metadata, :timber_context, %{})
    new_context = Context.add_context(current_context, data)

    Elixir.Logger.metadata([timber_context: new_context])
  end

  @doc """
  Creates a custom Timber event. Shortcut for `Timber.Events.CustomEvent.new/1`.
  """
  @spec event(Keyword.t) :: Timber.Events.CustomEvent.t
  defdelegate event(opts), to: Events.CustomEvent, as: :new

  @doc """
  Starts a timer for timing custom events. This timer can then be passed
  to `Timber.event/1` for inclusion in the event.

  ## Examples

    iex> require Logger
    iex> timer = Timber.start_timer()
    iex> # ... code to time ...
    iex> event_data = %{customer_id: "xiaus1934", amount: 1900, currency: "USD"}
    iex> event = Timber.event(name: :payment_received, data: event_data, timer: timer)
    iex> Logger.info("Received payment", timber_event: event)
    :ok
  """
  @spec start_timer() :: integer()
  def start_timer(),
    do: System.monotonic_time()
end
