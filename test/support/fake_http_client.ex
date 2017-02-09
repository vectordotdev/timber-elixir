defmodule Timber.FakeHTTPClient do
  use Timber.Stubbing

  def request(method, url, headers, body, opts) do
    add_function_call(:request, {method, url, headers, body, opts})
  end

  def get_request_calls do
    get_function_calls(:request)
  end
end