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

  alias Timber.ContextEntry

  @doc """
  Adds a context entry to the stack
  """
  @spec add_context(ContextEntry.context_data) :: :ok
  def add_context(data) do
    type = ContextEntry.type_for_data(data)

    c = ContextEntry.new(Timber.Utils.now(), type, data)

    current_metadata = Elixir.Logger.metadata()
    current_context = Keyword.get(current_metadata, :timber_context, [])
    new_context = current_context ++ [c]

    Elixir.Logger.metadata([timber_context: new_context])
  end
end
