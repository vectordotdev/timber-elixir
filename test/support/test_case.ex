defmodule Timber.TestCase do
  use ExUnit.CaseTemplate, async: false

  setup _tags do
    Timber.FakeHTTPClient.reset()
    :ok
  end
end
