defmodule Timber.Ecto do
  @moduledoc """
  Timber integration for Ecto

  Timber can hook into Ecto's logging system to gather event
  about queries including the text of the query and the time
  it took to execute.

  To install Timber's event collector, you only need to modify the
  application configuration on a per-repository basis. Each repository
  has a configuration key `:loggers` that accepts a list of three element
  tuples where each tuple describes a log event consumer. The default list
  is `[{Ecto.LogEntry, :log, []}]` which tells the repository to log every
  event to `Ecto.LogEntry.log/1`. It is recommended you keep that entry in
  the list since it actually writes a log about the query.

  The tuple for Timber's context collector is `{Timber.Ecto, :add_context, []}`.
  Many applications will have only one repository named `Repo`, which
  makes adding this easy. For example, to add it to the repository
  `MyApp.Repo`:

  ```elixir
  config :my_app, MyApp.Repo,
    loggers: [{Timber.Ecto, :log, []}]
  ```

  If you have set Ecto to log every query in production, you will need
  to make sure that Timber appears _before_ the standard Ecto entry.
  That way when Ecto writes a log, it will include the context that Timber
  has gathered.

  ### Timing

  The time reported in the context is the amount of time the query
  took to execute on the database, as measured by Ecto. It does not
  include the time that the query spent in the pool's queue or the
  time spent decoding the response from the database.
  """

  require Logger

  alias Timber.Events.SQLQueryEvent

  @doc """
  Takes an `Ecto.LogEntry` struct and adds it to the Timber context

  This function is designed to be called from Ecto's built-in logging
  system (see the module's documentation). It takes an `Ecto.LogEntry`
  entry struct and parses it into a `Timber.Event.SQLQueryEvent`
  which is then logged.
  """
  @spec log(Ecto.LogEntry.t) :: Ecto.LogEntry.t
  def log(%Ecto.LogEntry{query: query, query_time: time_native} = entry) do
    query_text = resolve_query(query, entry)
    # The time is given in native units which the VM determines. We have
    # to convert them to the desired unit
    time_ms = System.convert_time_unit(time_native, :native, :milliseconds)

    event = SQLQueryEvent.new(
      sql: query_text,
      time_ms: time_ms
    )

    Logger.log(event.description, timber_event: event)

    entry
  end

  # Interestingly, the query is not necessarily a String.t, it
  # can also be a single-arity function which, given the log entry
  # as a parameter, will return a String.t
  #
  # resolve_query will either determine that it's a String.t and
  # return it or resolve the function to get a String.t
  #
  # It's possible this is a hold-over from Ecto 1
  @spec resolve_query(String.t | (Ecto.LogEntry.t -> String.t), Ecto.LogEntry.t) :: String.t
  defp resolve_query(q, entry) when is_function(q), do: q.(entry)
  defp resolve_query(q, _) when is_binary(q), do: q
end
