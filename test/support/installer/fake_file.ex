defmodule Timber.Installer.FakeFile do
  use Timber.Stubbing

  def close(file) do
    get_stub(:close).(file)
  end

  def open(path, opts) do
    get_stub(:open).(path, opts)
  end

  def read(path) do
    get_stub(:read).(path)
  end
end