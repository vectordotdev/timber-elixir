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
  alias Timber.Context

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

  @doc false
  # Handles the application callback start/2
  #
  # Starts an empty supervisor in order to comply with callback expectations
  #
  # This is the function that starts up the error logger listener
  #
  def start(_type, _opts) do
    capture_errors = Application.get_env(:timber, :capture_errors, false)
    disable_tty = Application.get_env(:timber, :disable_kernel_error_tty, capture_errors)

    if capture_errors do
      :error_logger.add_report_handler(Timber.ErrorLogger)
    end

    if disable_tty do
      :error_logger.tty(false)
    end

    children = []
    opts = [strategy: :one_for_one, name: Timber.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
