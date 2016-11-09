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
end
