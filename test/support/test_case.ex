defmodule Timber.TestCase do
  use ExUnit.CaseTemplate, async: false

  setup _tags do
    Timber.Installer.FakeFile.reset()
    Timber.Installer.FakeHTTPClient.reset()
    Timber.Installer.FakeIO.reset()
    Timber.Installer.FakePath.reset()
    Timber.FakeHTTPClient.reset()
    :ok
  end
end