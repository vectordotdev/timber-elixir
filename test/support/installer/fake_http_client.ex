defmodule Timber.Installer.FakeHTTPClient do
  use Timber.Stubbing

  def request!(session_id, method, path, opts \\ []) do
    get_stub!(:request!).(session_id, method, path, opts)
  end
end