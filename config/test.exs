use Mix.Config

config :sasl, :sasl_error_logger, false

config :logger, level: :info

config :timber,
  api_key: "api_key"

config :timber, :install,
  file_client: Timber.Installer.FakeFile,
  http_client: Timber.Installer.FakeHTTPClient,
  io_client: Timber.Installer.FakeIO,
  path_client: Timber.Installer.FakePath
