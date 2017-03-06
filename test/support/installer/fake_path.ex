defmodule Timber.Installer.FakePath do
  use Timber.Stubbing

  def wildcard(path) do
    get_stub(:wildcard).(path)
  end
end