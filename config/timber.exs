use Mix.Config

# Structure phoenix logs
config :elixir_phoenix_example_app, ElixirPhoenixExampleApp.Endpoint,
  instrumenters: [Timber.Integrations.PhoenixInstrumenter]

# Structure Ecto logs
config :elixir_phoenix_example_app, ElixirPhoenixExampleApp.Repo,
  loggers: [{Timber.Integrations.EctoLogger, :log, [:info]}]

# Use Timber as the logger backend
config :logger,
  backends: [Timber.LoggerBackend]

# Direct logs to STDOUT
config :timber,
  transport: Timber.Transports.IODevice

# Questions? Contact us at support@timber.io
