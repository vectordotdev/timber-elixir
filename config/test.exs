use Mix.Config

config :sasl, :sasl_error_logger, false

config :logger, level: :warn

config :timber,
  api_key: "api_key"

config :timber, :http_transport,
  http_client: Timber.FakeHTTPClient