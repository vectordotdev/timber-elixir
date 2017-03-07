defmodule Mix.Tasks.Timber.Install.ApplicationTest do
  use Timber.TestCase

  alias Mix.Tasks.Timber.Install.Application
  alias Mix.Tasks.Timber.Install.Application.MalformedApplicationPayload
  alias Timber.Installer.{FakeFile, FakeHTTPClient}

  describe "Mix.Tasks.Timber.Install.Application.new!/1" do
    test "bad application payload" do
      FakeHTTPClient.stub(:request!, fn ("GET", "/installer/application", "api_key") -> %{} end)
      assert_raise MalformedApplicationPayload, fn ->
        Application.new!("api_key")
      end
    end

    test "valid application payload" do
      FakeHTTPClient.stub(:request!, fn ("GET", "/installer/application", "api_key") ->
        %{"api_key" => "api_key", "heroku_drain_url" => "drain_url", "name" => "Timber",
          "platform_type" => "heroku", "slug" => "timber"}
      end)

      FakeFile.stub(:exists?, fn _file_path -> true end)

      result = Application.new!("api_key")
      assert result == %Application{api_key: "api_key",
        config_file_path: "config/config.exs",
        endpoint_file_path: "lib/timber_elixir/endpoint.ex",
        endpoint_module_name: "TimberElixir.Endpoint",
        heroku_drain_url: "drain_url", mix_name: "timber_elixir",
        module_name: "TimberElixir", name: "Timber",
        platform_type: "heroku",
        repo_file_path: "lib/timber_elixir/repo.ex",
        repo_module_name: "TimberElixir.Repo", slug: "timber",
        web_file_path: "web/web.ex"}
    end
  end
end