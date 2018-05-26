ExUnit.start()

Application.ensure_all_started(:hackney)

{:ok, _pid} = Timber.FakeHTTPClient.start_link()
{:ok, _pid} = Timber.Installer.FakeFile.start_link()
{:ok, _pid} = Timber.Installer.FakeHTTPClient.start_link()
{:ok, _pid} = Timber.Installer.FakeIO.start_link()
{:ok, _pid} = Timber.Installer.FakePath.start_link()
