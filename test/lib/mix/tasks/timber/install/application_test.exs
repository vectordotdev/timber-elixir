defmodule Mix.Tasks.Timber.Install.ApplicationTest do
  use Timber.TestCase

  alias Mix.Tasks.Timber.Install.Application
  alias Mix.Tasks.Timber.Install.Application.MalformedApplicationPayload
  alias Timber.Installer.{FakeFile, FakeHTTPClient}

  describe "Mix.Tasks.Timber.Install.Application.new!/1" do
    test "bad application payload" do
      FakeHTTPClient.stub(:request!, fn ("session_id", :get, "/installer/application", [api_key: "api_key"]) -> {200, %{}} end)
      assert_raise MalformedApplicationPayload, fn ->
        Application.new!("session_id", "api_key")
      end
    end

    test "valid application payload" do
      FakeHTTPClient.stub(:request!, fn ("session_id", :get, "/installer/application", [api_key: "api_key"]) ->
        {200, %{"api_key" => "api_key", "heroku_drain_url" => "drain_url", "name" => "Timber",
          "platform_type" => "heroku", "slug" => "timber"}}
      end)

      FakeFile.stub(:exists?, fn _file_path -> true end)

      result = Application.new!("session_id", "api_key")
      assert result == %Application{api_key: "api_key",
        config_file_path: "config/config.exs",
        endpoint_file_path: "lib/timber_elixir/endpoint.ex",
        endpoint_module_name: "TimberElixir.Endpoint",
        heroku_drain_url: "drain_url", mix_name: "timber_elixir",
        module_name: "TimberElixir", name: "Timber",
        platform_type: "heroku",
        repo_module_name: "TimberElixir.Repo", slug: "timber",
        web_file_path: "web/web.ex"}
    end
  end

  describe "Mix.Tasks.Timber.Install.Application.wait_for_logs/2" do
    test "204" do
      FakeHTTPClient.stub(:request!, fn ("session_id", :get, "/installer/has_logs", [api_key: "api_key"]) -> {204, ""} end)
      result = Application.wait_for_logs(%{api_key: "api_key", platform_type: "heroku"}, "session_id")
      assert result == :ok
    end
  end
end