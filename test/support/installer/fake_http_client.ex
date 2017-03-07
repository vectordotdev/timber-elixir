defmodule Timber.Installer.FakeHTTPClient do
  use Timber.Stubbing

  def request!(method, path, api_key) do
    get_stub(:request!).(method, path, api_key)
  end
end