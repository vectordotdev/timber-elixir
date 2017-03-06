defmodule Timber.Installer.FakeHTTPClient do
  use Timber.Stubbing

  def request(method, path) do
    get_stub(:request).(method, path)
  end
end