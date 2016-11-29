defmodule Timber.Config do
  @env_key :timber

  def capture_errors?(),
    do: Application.get_env(@env_key, :capture_errors, false)

  def disable_tty?(),
    do: Application.get_env(@env_key, :disable_kernel_error_tty, capture_errors?())

  def event_key(),
    do: Application.get_env(@env_key, :event_key, :event)

  def io_device(),
    do: Application.get_env(@env_key, :io_device, [])

  @spec phoenix_instrumentation_level(atom) :: atom
  def phoenix_instrumentation_level(default) do
    Application.get_env(@env_key, :instrumentation_level, default)
  end

  def transport(),
    do: Application.get_env(@env_key, :transport)
end