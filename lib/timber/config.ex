defmodule Timber.Config do
  @env_key :timber

  def api_key! do
    case Application.get_env(@env_key, :api_key) do
      {:system, env_var_name} -> System.get_env(env_var_name)
      api_key when is_binary(api_key) -> api_key
      api_key -> raise(MissingAPIKeyError)
    end
  end

  def event_key, do: Application.get_env(@env_key, :event_key, :event)

  def http_client, do: Application.get_env(@env_key, :http_client)

  def http_client!, do: Application.fetch_env!(@env_key, :http_client)

  def http_url, do: Application.get_env(@env_key, :http_url)

  def json_encoder, do: Application.get_env(@env_key, :json_encoder, &Poison.encode_to_iodata!/1)

  @spec phoenix_instrumentation_level(atom) :: atom
  def phoenix_instrumentation_level(default) do
    Application.get_env(@env_key, :instrumentation_level, default)
  end

  @doc """
  Gets the transport specificed in the :timber configuration. The default is
  `Timber.Transports.IODevice`.
  """
  def transport, do: Application.get_env(@env_key, :transport, Timber.Transports.IODevice)

  #
  # Errors
  #

  defmodule MissingAPIKeyError do
    message =
      """
      We couldn't find an API key for Timber. Please ensure that you have configured your
      Timber API properly. Ex:

      config :timber,
        api_key: {:system, "TIMBER_API_KEY"} # or pass the key directly
      """

    defexception message: message
  end
end