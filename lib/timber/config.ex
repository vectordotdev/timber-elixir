defmodule Timber.Config do
  @application :timber
  @default_http_body_max_bytes 2048

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
  Configuration for the `:body` byte size limit in the `Timber.Events.HTTP*` events.
  Bodies that exceed this limit will be truncated to this byte limit. The default is
  `2048` with a maximum allowed value of `8192`.

  # Example

  ```elixir
  config :timber, :http_body_size_limit, 2048
  ```
  """
  def http_body_size_limit,
    do: Application.get_env(@application, :http_body_size_limit, @default_http_body_max_bytes)

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
  The specified function must take any data structure and return `iodata`. It
  should raise on encode failures.

  # Example

  ```elixir
  config :timber, :json_encoder, fn map -> encode(map) end
  ```
  """
  @spec json_encoder() :: (any -> iodata)
  def json_encoder,
    do: Application.get_env(@application, :json_encoder, &Poison.encode_to_iodata!/1)

  @doc """
  Unfortunately the `Elixir.Logger` produces timestamps with microsecond prevision.
  In a high volume system, this can produce logs with matching timestamps, making it
  impossible to preseve the order of the logs. By enabling this, Timber will discard
  the default `Elixir.Logger` timestamps and use it's own with nanosecond precision.

  # Example

  ```elixir
  config :timber, :nanosecond_timestamps, true
  ```
  """
  @spec use_nanosecond_timestamps? :: boolean
  def use_nanosecond_timestamps? do
    Application.get_env(@application, :nanosecond_timestamps, true)
  end

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

  def capture_errors?, do: Application.get_env(@application, :capture_errors, false)

  def disable_tty?,
    do: Application.get_env(@application, :disable_kernel_error_tty, capture_errors?())
end
