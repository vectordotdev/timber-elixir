defmodule Timber.FakeHTTPClient do
  use Timber.Stubbing

  def async_request(method, url, headers, body) do
    # Track the function call
    add_function_call(:async_request, {method, url, headers, body})

    stub = get_stub(:async_request)

    if stub do
      stub.(method, url, headers, body)
    else
      stream_reference = "1234"

      # Send the response message so the client isn't waiting indefinitely
      Process.send(self(), {:hackney_response, stream_reference, :done}, [])

      # Return back with the same stream reference
      {:ok, stream_reference}
    end
  end

  def request(method, url, headers, body) do
    add_function_call(:request, {method, url, headers, body})
    stub = get_stub(:request)
    stub.(method, url, headers, body)
  end

  def wait_on_request(ref) do
    receive do
      {:hackney_response, ^ref, :done} -> :ok
      _else -> wait_on_request(ref)
    end
  end

  def get_async_request_calls do
    get_function_calls(:async_request)
  end
end
