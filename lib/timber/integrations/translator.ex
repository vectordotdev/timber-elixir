defmodule Timber.Integrations.Translator do
  alias Timber.Events.ErrorEvent
  @moduledoc """
  This module implements a Logger translator to take advantage of
  the richer metadata available from Logger in OTP 21 and Elixir 1.7+.

  Including the translator allows for crash reasons and stacktraces to be
  included as structured metadata within Timber.

  The translator depends on using Elixir's internal Logger.Translator, and
  is not compatible with other translators as a Logger event can only be
  translated once.

  To install, add the translator in your application's start function:
  ```
  # ...
  :ok = Logger.add_translator({Timber.Integrations.Translator, :translate})

  opts = [strategy: :one_for_one, name: MyApp.Supervisor]
  Supervisor.start_link(children, opts)
  ```
  """

  def translate(min_level, level, kind, message) do
    case Logger.Translator.translate(min_level, level, kind, message) do
      {:ok, char, metadata} ->
        new_metadata = transform_metadata(metadata)

        {:ok, char, new_metadata}
      {:ok, char} ->
        {:ok, char}
      :skip -> :skip
      :none -> :none
    end
  end

  def transform_metadata(nil), do: []
  def transform_metadata(metadata) do
    with {:ok, crash_reason} <- Keyword.fetch(metadata, :crash_reason),
         {:ok, event} <- get_error_event(crash_reason)
    do
      Timber.Event.to_metadata(event)
      |> Keyword.merge(metadata)
    else
      _ ->
        metadata
    end
  end

  defp get_error_event({{%{__exception__: true} = error, stacktrace}, _stack})
  when is_list(stacktrace) do
    {:ok, build_error_event(error, stacktrace, :error)}
  end

  defp get_error_event({%{__exception__: true} = error, stacktrace}) when is_list(stacktrace) do
    {:ok, build_error_event(error, stacktrace, :error)}
  end

  defp get_error_event({{type, reason}, stacktrace}) when is_list(stacktrace) do
    {:ok, build_error_event(reason, stacktrace, type)}
  end

  defp get_error_event({error, stacktrace}) when is_list(stacktrace) do
    {:ok, build_error_event(error, stacktrace, :error)}
  end

  defp get_error_event(_) do
    {:error, :no_info}
  end

  defp build_error_event(%{__exception__: true} = error, stacktrace, _type) do
    ErrorEvent.from_exception(error)
    |> ErrorEvent.add_backtrace(stacktrace)
  end

  defp build_error_event(error, stacktrace, _type) do
    ErlangError.normalize(error, stacktrace)
    |> ErrorEvent.from_exception()
    |> ErrorEvent.add_backtrace(stacktrace)
  end
end
