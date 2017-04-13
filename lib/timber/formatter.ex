defmodule Timber.Formatter do
  @moduledoc """
  Provides utilities for formatting log lines as text

  This formatter is designed for use with the default `:console` backend provided by
  Elixir Logger. To use is, you'll need to configure the console backend to call
  the `Timber.Formatter.format/4` function instead of its default formatting function.
  This is done with a simple configuration change. You'll also need to let `:console`
  know that the metadata keys `:timber_context` and `:event` should be passed on.

  The result of the configuration looks like:

  ```elixir
  config :logger, backends: [:console]
  config :logger, :console,
    format: {Timber.Formatter, :format},
    metadata: [:timber_context, :event, :application, :file, :function, :line, :module]
  ```

  Further configuration options available on this module are documented below.

  ## Configuration Recommendations: Development vs. Production

  In a standard Elixir project, you will probably have different configuration files
  for your development and production setups. These configuration files typically
  take the form of `config/dev.exs` and `config/prod.exs` which override defaults set
  in `config/config.exs`.

  Timber's defaults are production ready, but the production settings also assume that
  you'll be viewing the logs through the Timber console, so they forego some niceties
  that help when developing locally. Therefore, to help with local development, we
  recommended this configuration for your `:dev` environment:

  ```
  # config/dev.exs

  config :timber, Timber.Formatter,
    colorize: true,
    format: :logfmt,
    print_timestamps: true
    print_log_level: true
  ```

  This will configure Timber to output logs in logfmt instead of JSON, print the log
  level and timestamps, and colorize the logs.

  ## Transport Configuration Options

  The following options are available when configuring the formatter:

  #### `colorize`

  When `true`, the log level will be printed in a corresponding color using
  ANSI console control characters to help identify it.

  When `false`, the log level will be printed out as standard text.

  _Defaults to `true`._

  #### `escape_new_lines`

  When `true`, new lines characters are escaped as `\\n`.

  When `false`, new lines characters are left alone.

  This circumvents issues with output devices (like Heroku Logplex) that will tranform
  line breaks into multiple log lines.

  The default depends on on the environment variable `HEROKU`. If the environment variable
  is present, this will be set to `true`. Otherwise, this defaults to `false`. Setting the
  value in your application configuration will always override the initialized setting.

  #### `format`

  Determines the output format to use. Even though the Timber service is designed
  to receive log metadata in JSON format, it's not the prettiest format to look at when
  you're developing locally. Therefore, we let you print the metadata in logfmt locally
  to make it easier on the eyes.

  Valid values:

    - `:json`
    - `:logfmt` (not supported in production)

  _Defaults to `:json`._

  #### `print_log_level`

  When `true`, the log level is printed in brackets as part of your log message.

  When `false`, the log level is not printed.

  Regardless of the setting used, the log level will be recorded as part of Timber's
  metadata. Setting this to `false` is recommended for production usage if you only
  use Timber for viewing logs.

  _Defaults to `false`._

  #### `print_metadata`

  The Timber metadata contains additional information about your log lines, but this
  can become unwieldy in local development scenarios.

  When `true`, the Timber metadata is printed out at the end of the log line (starting
  with the indicator "@metadata").

  When `false`, the Timber metadata is not printed.

  Note: This should _always_ be `true` in production.

  _Defaults to `true`._

  #### `print_timestamps`

  When `true`, the timestamp for the log will be output at the front
  of the statement.

  When `false`, the timestamp will be suppressed. This is only useful in situations
  where the log will be written to an evented IO service that automatically adds
  timestamps for incoming data, like Heroku Logplex.

  Regardless of the setting used, the timestamp will be recorded as part of Timber's
  metadata. Setting this to `false` is recommended for production usage if you only
  use Timber for viewing logs.

  _Defaults to `false`._
  """

  @default_colorize true
  @default_escape_new_lines false
  @default_format :json
  @default_print_log_level false
  @default_print_metadata true
  @default_print_timestamps false
  @metadata_delimiter " @metadata "

  alias Timber.LogEntry

  @type configuration :: %{
    required(:colorize) => boolean,
    required(:escape_new_lines) => boolean,
    required(:format) => :json | :logfmt,
    required(:print_log_level) => boolean,
    required(:print_metadata) => boolean,
    required(:print_timestamps) => boolean
  }

  @doc """
  Handles formatting a log for the `Logger` application

  This function allows you to integrate Timber with the default `:console` backend
  distributed with the Elixir `Logger` application. By default, metadata will be
  output as a JSON document after the `@metadata` keyword on the line. You can also
  opt for the output to be in logfmt by setting the appropriate configuration key.
  """
  def format(level, message, ts, metadata) do
    configuration = get_configuration()
    log_entry = LogEntry.new(ts, level, message, metadata)
    level_b = colorize_log_level(log_entry.level, configuration.colorize)

    metadata =
      if configuration.print_metadata do
        log_entry
        |> LogEntry.to_string!(configuration.format, only: [:dt, :level, :event, :context])
        |> wrap_metadata()
      else
        []
      end

    line_output =
      [message, metadata]
      |> add_log_level(level_b, configuration.print_log_level)
      |> add_timestamp(log_entry.dt, configuration.print_timestamps)
      |> escape_new_lines(configuration.escape_new_lines)

    # Prevents the final new line from being escaped
    [line_output, ?\n]
  end

  @spec get_configuration() :: configuration
  defp get_configuration() do
    options = Application.get_env(:timber, __MODULE__, [])
    colorize = Keyword.get(options, :colorize, @default_colorize)
    escape_new_lines = Keyword.get(options, :escape_new_lines, @default_escape_new_lines)
    format = Keyword.get(options, :format, @default_format)
    print_log_level = Keyword.get(options, :print_log_level, @default_print_log_level)
    print_metadata = Keyword.get(options, :print_metadata, @default_print_metadata)
    print_timestamps = Keyword.get(options, :print_timestamps, @default_print_timestamps)

    %{
      colorize: colorize,
      escape_new_lines: escape_new_lines,
      format: format,
      print_log_level: print_log_level,
      print_metadata: print_metadata,
      print_timestamps: print_timestamps
    }
  end

  @spec add_timestamp(IO.chardata, IO.chardata, boolean) :: IO.chardata
  defp add_timestamp(message, _, false), do: message
  defp add_timestamp(message, timestamp, true) do
    [timestamp, " " |  message]
  end

  @spec wrap_metadata(IO.chardata) :: IO.chardata
  defp wrap_metadata(metadata) do
    [@metadata_delimiter, metadata]
  end

  @spec add_log_level(IO.chardata, IO.charadata, boolean) :: IO.chardata
  defp add_log_level(message, _, false), do: message
  defp add_log_level(message, log_level, true) do
    ["[", log_level, "] " | message ]
  end

  @spec colorize_log_level(LoggerBackend.level, boolean) :: IO.chardata
  defp colorize_log_level(level_a, false), do: Atom.to_string(level_a)
  defp colorize_log_level(level_a, true) do
    color = log_level_color(level_a)
    level_b = Atom.to_string(level_a)

    [color, level_b]
    |> IO.ANSI.format(true)
  end

  @spec log_level_color(LoggerBackend.level) :: atom
  defp log_level_color(:debug), do: :cyan
  defp log_level_color(:warn), do: :yellow
  defp log_level_color(:error), do: :red
  defp log_level_color(_), do: :normal

  @spec escape_new_lines(IO.chardata, boolean) :: IO.chardata
  defp escape_new_lines(msg, false), do: msg
  defp escape_new_lines(msg, true) do
    to_string(msg)
    |> String.replace("\n", "\\n")
  end
end
