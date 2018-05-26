defmodule Mix.Tasks.Timber.Install.EndpointFileTest do
  use Timber.TestCase

  alias Mix.Tasks.Timber.Install.{API, EndpointFile}
  alias Timber.Installer.{FakeFile, FakeFileContents, FakeHTTPClient, FakeIO}

  describe "Mix.Tasks.Timber.Install.EndpointFile.update!/1" do
    test "updates properly" do
      FakeFile.stub(:read, fn "file_path" ->
        {:ok, FakeFileContents.default_endpoint_contents()}
      end)

      FakeFile.stub(:open, fn "file_path", [:write] -> {:ok, "file device"} end)

      expected_contents = FakeFileContents.new_endpoint_contents()

      FakeIO.stub(:binwrite, fn "file device", ^expected_contents -> :ok end)
      FakeFile.stub(:close, fn "file device" -> {:ok, "file device"} end)

      FakeHTTPClient.stub(:request, fn :post,
                                       [
                                         {'Authorization', 'Basic YXBpX2tleQ=='},
                                         {'X-Installer-Session-Id', _session_id}
                                       ],
                                       "https://api.timber.io/installer/events",
                                       _opts ->
        {:ok, 204, ""}
      end)

      api = %API{api_key: "api_key", session_id: "session_id"}

      result = EndpointFile.update!("file_path", api)
      assert result == :ok
    end

    test "updates only once" do
      FakeFile.stub(:read, fn "file_path" -> {:ok, FakeFileContents.new_endpoint_contents()} end)
      FakeFile.stub(:open, fn "file_path", [:write] -> {:ok, "file device"} end)

      expected_contents = FakeFileContents.new_endpoint_contents()

      FakeIO.stub(:binwrite, fn "file device", ^expected_contents -> :ok end)
      FakeFile.stub(:close, fn "file device" -> {:ok, "file device"} end)

      FakeHTTPClient.stub(:request, fn :post,
                                       [
                                         {'Authorization', 'Basic YXBpX2tleQ=='},
                                         {'X-Installer-Session-Id', _session_id}
                                       ],
                                       "https://api.timber.io/installer/events",
                                       _opts ->
        {:ok, 204, ""}
      end)

      api = %API{api_key: "api_key", session_id: "session_id"}
      result = EndpointFile.update!("file_path", api)
      assert result == :ok
    end
  end
end
