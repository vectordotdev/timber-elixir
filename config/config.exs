# This file is used for configuration during development of the package.
# To set defaults for users of the package, please use the `env()` function
# in `mix.exs`.
use Mix.Config

config :logger, :utc_log, true
config :logger, :handle_otp_reports, false

config :logger, backends: [Timber.LoggerBackend]
config :timber, transport: Timber.Transports.IODevice, debug_io_device: :stdio


# The file config/config.secret.exs can be used for local
# configuration
if File.exists?("config/config.secret.exs") do
  import_config "config.secret.exs"
end

if File.exists?("config/#{Mix.env}.exs") do
  import_config "#{Mix.env}.exs"
end
