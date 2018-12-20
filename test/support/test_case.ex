defmodule Timber.TestCase do
  @moduledoc false
  use ExUnit.CaseTemplate, async: false

  setup _tags do
    Timber.HTTPClients.Fake.reset()
    :ok
  end
end
