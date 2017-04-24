defmodule Timber.Config do
  @application :timber

  @doc """
  Your Timber application API key. This can be obtained after you create your
  application in https://app.timber.io

  # Example

  ```elixir
  config :timber, :api_key, "abcd1234"
  ```
  """
  def api_key do
    case Application.get_env(@application, :api_key) do
      {:system, env_var_name} -> System.get_env(env_var_name)
      api_key when is_binary(api_key) -> api_key
      _else -> nil
    end
  end

  @doc """
  Helpful to inspect internal Timber activity; a useful debugging utility.
  If specified, Timber will write messages to this device. We cannot use the
  standard Logger directly because it would create an infinite loop.
  """
  def debug_io_device do
    Application.get_env(@application, :debug_io_device)
  end

  @doc """
  Change the name of the `Logger` metadata key that Timber uses for events.
  By default, this is `:event`

  # Example

  ```elixir
  config :timber, :event_key, :timber_event
  Logger.info("test", timber_event: my_event)
  ```
  """
  def event_key, do: Application.get_env(@application, :event_key, :event)

  @doc """
  Allows for the sanitizations of custom header keys. This should be used to
  ensure sensitive data, such as API keys, do not get logged.

  **Note, the keys passed must be lowercase!**

  Timber normalizes headers to be downcased before comparing them here. For
  performance reasons it is advised that you pass lower cased keys.

  # Example

  ```elixir
  config :timber, :header_keys_to_sanitize, ["my-sensitive-header-name"]
  ```
  """
  def header_keys_to_sanitize, do: Application.get_env(@application, :header_keys_to_sanitize, [])

  @doc """
  Configuration for the `:body` size limit in the `Timber.Events.HTTP*` events.
  Bodies that exceed this limit will be truncated to this limit.

  Please take care with this value, increasing it too high can mean very large
  payloads and very high outgoing network activity.

  # Example

  ```elixir
  config :timber, :http_body_size_limit, 5000
  ```
  """
  def http_body_size_limit, do: Application.get_env(@application, :http_body_size_limit, 2000)

  @doc """
  Alternate URL for delivering logs. This is helpful if you want to use a proxy,
  for example.

  # Example

  ```elixir
  config :timber, :http_url, "https://123.123.123.123"
  ```
  """
  def http_url, do: Application.get_env(@application, :http_url)

  @doc """
  Specify a different JSON encoder function. Timber uses `Poison` by default.

  # Example

  ```elixir
  config :timber, :json_encoder, fn map -> encode(map) end
  ```
  """
  def json_encoder, do: Application.get_env(@application, :json_encoder, &Poison.encode_to_iodata!/1)

  @doc """
  Specify the log level that phoenix log lines write to. Such as template renders.

  # Example

  ```elixir
  config :timber, :instrumentation_level, :info
  ```
  """
  @spec phoenix_instrumentation_level(atom) :: atom
  def phoenix_instrumentation_level(default) do
    Application.get_env(@application, :instrumentation_level, default)
  end

  @doc """
  Gets the transport specificed in the :timber configuration. The default is
  `Timber.Transports.IODevice`.
  """
  def transport, do: Application.get_env(@application, :transport, Timber.Transports.IODevice)
end
