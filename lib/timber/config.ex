defmodule Timber.Config do
  @moduledoc """
  Configuration for the Timber library

  All supported options are described within their respective method:

  * `:api_key` - `api_key/0`
  * `:debug_io_device` - `debug_io_device/0`
  * `:event_key` - `event_key/0`
  * `:http_client` - `http_client/0`
  * `:http_url` - `http_url/0`
  * `:nanosecond_timestamps` - `use_nanosecond_timestamps?/0`

  Each configuration option can be set like the following:

      config :timber,
        key: :value

  Please see the respective method for examples.
  """

  alias Timber.HTTPClients.Hackney, as: HackneyHTTPClient

  @application :timber
  @default_http_url "https://logs.timber.io/frames"

  @doc """
  Your Timber application API key.

  This can be obtained after you create your account in https://app.timber.io

  ## Example

      config :timber,
        api_key: "abcd1234"

  """
  def api_key do
    case Application.get_env(@application, :api_key) do
      {:system, env_var_name} ->
        get_env_with_warning(env_var_name)

      api_key when is_binary(api_key) ->
        api_key

      _else ->
        nil
    end
  end

  @doc """
  Helpful to inspect internal Timber activity; a useful debugging utility.

  If specified, Timber will write messages to this device. We cannot use the
  standard `Logger` directly because it would create an infinite loop since Timber
  operated within the `Logger`.

  Default: `nil`

  ## Example

      config :timber,
        debug_io_device: :stdio

  """
  def debug_io_device do
    Application.get_env(@application, :debug_io_device)
  end

  @doc """
  Change the name of the `Logger` metadata key that Timber uses for events.
  By default, this is `:event`

  Default: `:event`

  ## Example

      config :timber,
        event_key: :timber_event

  Then use it like so:

      Logger.info("test", timber_event: my_event)

  """
  def event_key,
    do: Application.get_env(@application, :event_key, :event)

  @doc """
  Alternate URL for delivering logs. This is helpful if you want to use a proxy,
  for example.

  Default: `HackneyHTTPClient`

  ## Example

      config :timber,
        http_client: Timber.HTTPClients.Hackney

  """
  def http_client,
    do: Application.get_env(@application, :http_client, HackneyHTTPClient)

  @doc """
  Alternate URL for delivering logs. This is helpful if you want to use a proxy,
  for example.

  Default: #{@default_http_url}

  ## Example

      config :timber, :http_url, "#{@default_http_url}"

  """
  def http_url do
    case Application.get_env(@application, :http_url, @default_http_url) do
      {:system, env_var_name} ->
        get_env_with_warning(env_var_name)

      http_url when is_binary(http_url) ->
        http_url

      _else ->
        nil
    end
  end

  @doc """
  Use nanoseconds, instead of the default microseconds, for log timestamps.

  Unfortunately the `Elixir.Logger` produces timestamps with microsecond precision.
  This is no adequate in a high volume system, resulting in logs with the same
  timestamps, making it difficult to preseve the exact order the logs were created.
  By enabling this, Timber will discard the default `Elixir.Logger` timestamps and
  use it's own with nanosecond precision.

  Default: `true`

  ## Example

      config :timber,
        nanosecond_timestamps: true

  """
  @spec use_nanosecond_timestamps? :: boolean
  def use_nanosecond_timestamps? do
    Application.get_env(@application, :nanosecond_timestamps, true)
  end

  #
  # Util
  #

  defp get_env_with_warning(name) do
    case System.get_env(name) do
      nil ->
        Timber.log(:warn, fn ->
          "The #{name} env var is not set!"
        end)

        nil

      value ->
        value
    end
  end
end
