ExUnit.start()

Application.ensure_all_started(:hackney)

{:ok, _pid} = Timber.FakeHTTPClient.start_link()
