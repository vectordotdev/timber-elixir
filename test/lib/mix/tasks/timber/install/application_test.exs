defmodule Mix.Tasks.Timber.Install.ApplicationTest do
  use Timber.TestCase

  alias Mix.Tasks.Timber.Install.{API, Application}
  alias Mix.Tasks.Timber.Install.Application.MalformedApplicationPayload
  alias Timber.Installer.{FakeFile, FakeHTTPClient}

  describe "Mix.Tasks.Timber.Install.Application.new!/1" do
    test "bad application payload" do
      FakeHTTPClient.stub(:request, fn (:get, [{'Authorization', 'Basic YXBpX2tleQ=='}, {'X-Installer-Session-Id', 'session_id'}], "https://api.timber.io/installer/application", []) -> {:ok, 200, "{\"data\": {}}"} end)
      assert_raise MalformedApplicationPayload, fn ->
        api = %API{api_key: "api_key", session_id: "session_id"}
        Application.new!(api)
      end
    end

    test "valid application payload" do
      FakeHTTPClient.stub(:request, fn (:get, [{'Authorization', 'Basic YXBpX2tleQ=='}, {'X-Installer-Session-Id', 'session_id'}], "https://api.timber.io/installer/application", []) ->
        {:ok, 200, "{\"data\": {\"slug\":\"timber\",\"platform_type\":\"heroku\",\"name\":\"Timber\",\"heroku_drain_url\":\"drain_url\",\"api_key\":\"api_key\"}}"}
      end)

      FakeFile.stub(:exists?, fn _file_path -> true end)

      api = %API{api_key: "api_key", session_id: "session_id"}
      result = Application.new!(api)
      assert result == %Application{api_key: "api_key",
             heroku_drain_url: "drain_url", mix_name: "timber_elixir",
             module_name: "TimberElixir", name: "Timber",
             platform_type: "heroku", slug: "timber"}
    end
  end
end