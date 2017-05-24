defmodule Timber.Integrations.EctoLogger do
  @moduledoc """
  Timber integration for Ecto.

  Timber can hook into Ecto's logging system to gather information
  about queries including the text of the query and the time
  it took to execute. This information is then logged as a
  `Timber.Events.SQLQueryEvent`.

  To install Timber's Ecto event collector, you only need to modify the
  application configuration on a per-repository basis. Each repository
  has a configuration key `:loggers` that accepts a list of three element
  tuples where each tuple describes a log event consumer. If you do not
  have a `:loggers` key specified, Ecto uses the default list of
  `[{Ecto.LogEntry, :log, []}]` which tells the repository to log every
  event to `Ecto.LogEntry.log/1`. In order to avoid duplicate logging,
  you will want to make sure it isn't in the list when using this
  event collector.

  The tuple for Timber's event collector is `{Timber.Integrations.EctoLogger, :log, []}`.
  Many applications will have only one repository named `Repo`, which
  makes adding this easy. For example, to add it to the repository
  `MyApp.Repo`:

  ```elixir
  config :my_app, MyApp.Repo,
    loggers: [{Timber.Integrations.EctoLogger, :log, []}]
  ```

  By default, queries are logged at the `:debug` level. If you want
  to use a custom level, simple add it to the list of arguments.
  For example, to log every query at the `:info` level:


  ```elixir
  config :my_app, MyApp.Repo,
    loggers: [{Timber.Integrations.EctoLogger, :log, [:info]}]
  ```

  ### Timing

  The time reported in the event is the amount of time the query
  took to execute on the database, as measured by Ecto. It does not
  include the time that the query spent in the pool's queue or the
  time spent decoding the response from the database.
  """

  require Logger

  alias Timber.Events.SQLQueryEvent

  @doc """
  Identical to log/2 except that it uses a default level of `:debug`
  """
  @spec log(Ecto.LogEntry.t) :: Ecto.LogEntry.t
  def log(event) do
    log(event, :debug)
  end

  @doc """
  Takes an `Ecto.LogEntry` struct and logs it as a `Timber.Event.SQLQueryEvent`
  event at the designated level

  This function is designed to be called from Ecto's built-in logging
  system (see the module's documentation). It takes an `Ecto.LogEntry`
  entry struct and parses it into a `Timber.Event.SQLQueryEvent`
  which is then logged at the designated level.
  """
  @spec log(Ecto.LogEntry.t) :: Ecto.LogEntry.t
  def log(%{query: query, query_time: time_native} = entry, level) do
    case resolve_query(query, entry) do
      {:ok, query_text} ->
        # The time is given in native units which the VM determines. We have
        # to convert them to the desired unit
        time_ms = System.convert_time_unit(time_native, :native, :milliseconds)

        event = %SQLQueryEvent{
          sql: query_text,
          time_ms: time_ms
        }

        message = SQLQueryEvent.message(event)
        metadata = Timber.Utils.Logger.event_to_metadata(event)

        Logger.log(level, message, metadata)

        entry

      {:error, :no_query} ->
        entry
    end
  end

  # Interestingly, the query is not necessarily a String.t, it
  # can also be a single-arity function which, given the log entry
  # as a parameter, will return a String.t
  #
  # resolve_query will either determine that it's a String.t and
  # return it or resolve the function to get a String.t
  #
  # It's possible this is a hold-over from Ecto 1
  @spec resolve_query(String.t | (Ecto.LogEntry.t -> String.t), Ecto.LogEntry.t) ::
    {:ok, String.t} | {:error, :no_query}
  defp resolve_query(q, entry) when is_function(q), do: {:ok, q.(entry)}
  defp resolve_query(q, _) when is_binary(q), do: {:ok, q}
  defp resolve_query(_q, _entry), do: {:error, :no_query}
end
