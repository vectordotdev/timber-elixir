defmodule Timber.HTTPClients.Fake do
  @moduledoc """
  Provides a fake HTTP client for testing
  """

  @behaviour Timber.HTTPClient

  def start_link do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def reset do
    Agent.update(__MODULE__, fn _ -> %{} end)
  end

  defp add_function_call(name, args) do
    calls = get_function_calls(name)
    Agent.update(__MODULE__, &Map.put(&1, name, calls ++ [args]))
  end

  def get_function_calls(name) do
    Agent.get(__MODULE__, &Map.get(&1, name, []))
  end

  def stub(name, stub) do
    Agent.update(__MODULE__, &Map.put(&1, String.to_atom("#{name}_stub"), stub))
  end

  def get_stub(name) do
    Agent.get(__MODULE__, &Map.get(&1, String.to_atom("#{name}_stub")))
  end

  def get_stub!(name) do
    get_stub(name) || raise("No stub found for #{__MODULE__}.#{name}")
  end

  def async_request(method, url, headers, body) do
    # Track the function call
    add_function_call(:async_request, {method, url, headers, body})

    stub = get_stub(:async_request)

    if stub do
      stub.(method, url, headers, body)
    else
      stream_reference = make_ref()

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
