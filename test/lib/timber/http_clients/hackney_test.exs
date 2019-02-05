defmodule Timber.HTTPClients.HackneyTest do
  use Timber.TestCase

  alias Timber.HTTPClients.Hackney, as: HackneyHTTPClient

  describe "Timber.HTTPClients.HackneyHTTPClient.handle_async_response/2" do
    test "handles :ok tuple response structures" do
      ref = make_ref()

      {:ok, 200, ""} =
        HackneyHTTPClient.handle_async_response(ref, {:hackney_response, ref, {:ok, 200, ""}})
    end

    test "handles :status tuple response structures" do
      ref = make_ref()

      {:ok, 200, ""} =
        HackneyHTTPClient.handle_async_response(ref, {:hackney_response, ref, {:status, 200, ""}})
    end

    test "handles :error tuples" do
      ref = make_ref()

      {:error, :reason} =
        HackneyHTTPClient.handle_async_response(ref, {:hackney_response, ref, {:error, :reason}})
    end

    test "passes on :done messages" do
      ref = make_ref()
      :pass = HackneyHTTPClient.handle_async_response(ref, {:hackney_response, ref, :done})
    end

    test "passes when the ref doesnt match" do
      orphaned_ref = make_ref()
      ref = make_ref()

      :pass =
        HackneyHTTPClient.handle_async_response(ref, {:hackney_response, orphaned_ref, :done})
    end
  end
end
