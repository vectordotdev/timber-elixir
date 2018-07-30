use Mix.Config

config :timber,
  api_key: "api_key",
  capture_errors: true


config :timber, :install,
  file_client: Timber.Installer.FakeFile,
  http_client: Timber.Installer.FakeHTTPClient,
  io_client: Timber.Installer.FakeIO,
  path_client: Timber.Installer.FakePath
