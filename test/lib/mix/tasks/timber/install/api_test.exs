defmodule Mix.Tasks.Timber.Install.APITest do
  use Timber.TestCase

  alias Mix.Tasks.Timber.Install.API
  alias Timber.Installer.FakeHTTPClient

  describe "Mix.Tasks.Timber.Install.API.wait_for_logs/2" do
    test "204" do
      FakeHTTPClient.stub(:request, fn (:get, [{'Authorization', 'Basic YXBpX2tleQ=='}, {'X-Installer-Session-Id', 'session_id'}], "https://api.timber.io/installer/has_logs", []) -> {:ok, 204, ""} end)
      api = %API{api_key: "api_key", session_id: "session_id"}
      result = API.wait_for_logs(api)
      assert result == :ok
    end
  end
end