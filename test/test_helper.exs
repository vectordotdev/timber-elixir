ExUnit.start()

Application.ensure_all_started(:hackney)

{:ok, _pid} = Timber.FakeFile.start_link()
{:ok, _pid} = Timber.FakeHTTPClient.start_link()
{:ok, _pid} = Timber.FakeIO.start_link()
{:ok, _pid} = Timber.FakePath.start_link()