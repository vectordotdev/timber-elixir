defmodule Mix.Tasks.Timber.Install.WebFileTest do
  use Timber.TestCase

  alias Mix.Tasks.Timber.Install.WebFile
  alias Timber.Installer.{FakeFile, FakeFileContents, FakeIO}

  describe "Mix.Tasks.Timber.Install.WebFile.update!/1" do
    test "updates properly" do
      FakeFile.stub(:read, fn "file_path" -> {:ok, FakeFileContents.default_web_contents()} end)
      FakeFile.stub(:open, fn "file_path", [:write] -> {:ok, "file device"} end)

      expected_contents = FakeFileContents.new_web_contents()

      FakeIO.stub(:binwrite, fn "file device", ^expected_contents -> :ok end)
      FakeFile.stub(:close, fn "file device" -> {:ok, "file device"} end)

      result = WebFile.update!("file_path")
      assert result == :ok
    end

    test "updates only once" do
      FakeFile.stub(:read, fn "file_path" -> {:ok, FakeFileContents.new_web_contents()} end)
      FakeFile.stub(:open, fn "file_path", [:write] -> {:ok, "file device"} end)

      expected_contents = FakeFileContents.new_web_contents()

      FakeIO.stub(:binwrite, fn "file device", ^expected_contents -> :ok end)
      FakeFile.stub(:close, fn "file device" -> {:ok, "file device"} end)

      result = WebFile.update!("file_path")
      assert result == :ok
    end
  end
end