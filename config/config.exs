# This file is used for configuration during development of the package.
# To set defaults for users of the package, please use the `env()` function
# in `mix.exs`.
use Mix.Config

config :logger, :utc_log, true

config :logger, backends: [:console]
config :logger, :console,
  format: {Timber.Formatter, :format}
  # For whatever reason, ExUnut.CaptureLog does not work when metadata is passed
  # metadata: [:timber_context, :event, :application, :file, :function, :line, :module, :meta]

config :plug,
  validate_header_keys_during_test: true

config :timber,
  header_keys_to_sanitize: ["sensitive-key"],
  nanosecond_timestamps: false

config :timber, Timber.Formatter,
  format: :logfmt

# The file config/config.secret.exs can be used for local
# configuration
if File.exists?("config/config.secret.exs") do
  import_config "config.secret.exs"
end

if File.exists?("config/#{Mix.env}.exs") do
  import_config "#{Mix.env}.exs"
end
