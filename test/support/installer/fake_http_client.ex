defmodule Timber.Installer.FakeHTTPClient do
  use Timber.Stubbing

  def start do
    :ok
  end

  def request(method, headers, url, opts \\ []) do
    get_stub!(:request).(method, headers, url, opts)
  end
end
