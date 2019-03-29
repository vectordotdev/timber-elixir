defmodule Timber.Formatter do
  @moduledoc """
  Provides utilities for formatting log lines as JSON text

  This formatter is designed for use with the default `:console` backend provided by
  Elixir Logger. To use this, you'll need to configure the console backend to call
  the `Timber.Formatter.format/4` function instead of its default formatting function.
  This is done with a simple configuration change. You'll also need to let `:console`
  know that `:all` metadata keys should be passed to the formatter.

  The result of the configuration looks like:

  ```elixir
  config :logger, backends: [:console]
  config :logger, :console,
    format: {Timber.Formatter, :format},
    metadata: :all
  ```

  Further configuration options available on this module are documented below.

  ## Configuration Recommendations: Development vs. Production

  In a standard Elixir project, you will probably have different configuration files
  for your development and production setups. These configuration files typically
  take the form of `config/dev.exs` and `config/prod.exs` which override defaults set
  in `config/config.exs`.

  Timber's defaults are production ready, but the production settings also assume that
  you'll be viewing the logs through the Timber console, so they forego some niceties
  that help when developing locally. Therefore, we recommend that you only include
  the `Timber.Formatter` in your production environments.

  ## Transport Configuration Options

  The following options are available when configuring the formatter:

  #### `escape_new_lines`

  When `true`, new lines characters are escaped as `\\n`.

  When `false`, new lines characters are left alone.

  This circumvents issues with output devices (like Heroku Logplex) that will tranform
  line breaks into multiple log lines.

  The default depends on on the environment variable `HEROKU`. If the environment variable
  is present, this will be set to `true`. Otherwise, this defaults to `false`. Setting the
  value in your application configuration will always override the initialized setting.
  """

  @default_escape_new_lines false

  alias Timber.LogEntry

  @type configuration :: %{
          required(:escape_new_lines) => boolean
        }

  @doc """
  Handles formatting a log for the `Logger` application

  This function allows you to integrate Timber with the default `:console` backend
  distributed with the Elixir `Logger` application. By default, lines are printed
  as encoded JSON strings,.
  """
  def format(level, message, ts, metadata) do
    configuration = get_configuration()
    log_entry = LogEntry.new(ts, level, message, metadata)

    line_output =
      log_entry
      |> LogEntry.encode_to_binary!(:json)
      |> escape_new_lines(configuration.escape_new_lines)

    # Prevents the final new line from being escaped
    [line_output, ?\n]
  end

  @spec get_configuration() :: configuration
  defp get_configuration() do
    options = Application.get_env(:timber, __MODULE__, [])
    escape_new_lines = Keyword.get(options, :escape_new_lines, @default_escape_new_lines)

    %{
      escape_new_lines: escape_new_lines
    }
  end

  @spec escape_new_lines(IO.chardata(), boolean) :: IO.chardata()
  defp escape_new_lines(message, false),
    do: message

  defp escape_new_lines(message, true) do
    message
    |> to_string()
    |> String.replace("\n", "\\n")
  end
end
