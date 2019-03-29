use Mix.Config

config :logger,
  backends: [:console],
  utc_log: true

config :logger, :console,
  colors: [enabled: false],
  format: {Timber.Formatter, :format}

config :timber,
  nanosecond_timestamps: false

# The file config/config.secret.exs can be used for local
# configuration
if File.exists?("config/config.secret.exs") do
  import_config "config.secret.exs"
end

if File.exists?("config/#{Mix.env()}.exs") do
  import_config "#{Mix.env()}.exs"
end
