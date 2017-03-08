defmodule Timber.Installer.FakeHTTPClient do
  use Timber.Stubbing

  def request!(method, path, opts \\ []) do
    get_stub(:request!).(method, path, opts)
  end
end