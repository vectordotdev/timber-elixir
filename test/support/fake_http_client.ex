defmodule Timber.FakeHTTPClient do
  use Timber.Stubbing

  def async_request(method, url, headers, body) do
    # Track the function call
    add_function_call(:request, {method, url, headers, body})

    stream_reference = "1234"

    # Send the response message so the client isn't waiting indefinitely
    Process.send(self(), {:hackney_response, stream_reference, :done}, [])

    # Return back with the same stream reference
    {:ok, stream_reference}
  end

  def done?(_message_type, _message_body), do: true

  def get_request_calls do
    get_function_calls(:request)
  end
end