defmodule Timber.Config do
  @env_key :timber

  def capture_errors?,
    do: Application.get_env(@env_key, :capture_errors, false)

  def disable_tty?,
    do: Application.get_env(@env_key, :disable_kernel_error_tty, capture_errors?())

  def event_key,
    do: Application.get_env(@env_key, :event_key, :event)

  def json_decoder,
    do: Application.get_env(@env_key, :json_decoder, &Poison.encode_to_iodata!/1)

  @spec phoenix_instrumentation_level(atom) :: atom
  def phoenix_instrumentation_level(default) do
    Application.get_env(@env_key, :instrumentation_level, default)
  end

  @doc """
  Gets the transport specificed in the :timber configuration. The default is
  `Timber.Transports.IODevice`.
  """
  def transport,
    do: Application.get_env(@env_key, :transport)
end