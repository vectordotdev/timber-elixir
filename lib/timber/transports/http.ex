defmodule Timber.Transports.HTTP do
  @moduledoc """
  An efficient HTTP transport that buffers and delivers log messages over HTTP to the
  Timber API. It uses batching, keep-alive connections, and msgpack to deliver logs with
  high-throughput and little overhead.

  ## Configuration

  ### Custom HTTP client

  By default, hackney is used via `Timber.Transports.HTTP.HackneyClient`. You can define your
  own HTTP client by defining it in your configuration:

  ```
  config :timber, :http_transport, http_client: MyHTTPClient
  ```

  Your client *must* implement the `Timber.Transports.HTTP.Client` beahvior. Please see that
  module for details.
  """

  @behaviour Timber.Transport

  alias Timber.LogEntry

  @typep t :: %__MODULE__{
    api_key: String.t,
    buffer_size: non_neg_integer,
    buffer: [] | [IO.chardata],
    flush_interval: non_neg_integer,
    max_buffer_size: pos_integer
  }

  # 5000 log lines should be well below 1mb and provide plenty of time to handle
  # network failures, etc.
  @default_max_buffer_size 5000
  @default_flush_interval 1000
  @default_http_client __MODULE__.HackneyClient
  @url "https://api.timber.io/frames"

  defstruct api_key: nil,
            buffer_size: 0,
            buffer: [],
            flush_interval: @default_flush_interval,
            max_buffer_size: @default_max_buffer_size

  @doc false
  @spec init() :: {:ok, t}
  def init() do
    config =
      config()
      |> Keyword.put(:api_key, Timber.Config.api_key!())
    case configure(config, %__MODULE__{}) do
      {:ok, state} ->
        flusher(state.flush_interval)
        {:ok, state}
      {:error, error} -> {:error, error}
    end
  end

  @doc false
  @spec configure(Keyword.t, t) :: {:ok, t}
  def configure(options, state) do
    api_key = Keyword.get(options, :api_key)
    max_buffer_size = Keyword.get(options, :max_buffer_size, @default_max_buffer_size)
    new_state = %{ state | api_key: api_key, max_buffer_size: max_buffer_size }
    {:ok, new_state}
  end

  @doc false
  @spec write(LogEntry.t, t) :: {:ok, t}
  def write(log_entry, state) do
    state = write_buffer(log_entry, state)
    if state.buffer_size > state.max_buffer_size do
      {:ok, flush(state)}
    else
      {:ok, state}
    end
  end

  # Writes a log entry into the buffer
  @spec write_buffer(LogEntry.t, t) :: t
  defp write_buffer(log_entry, %{buffer: buffer, buffer_size: buffer_size} = state) do
    %{state | buffer: buffer ++ [log_entry], buffer_size: buffer_size + 1}
  end

  # Handle the flusher step, this recursively calls itself.
  def handle_info(:flusher_step, state) do
    new_state = flush(state)
    flusher(state.flush_interval)
    {:ok, new_state}
  end
  # Do nothing for everything else.
  def handle_info(_, state) do
    {:ok, state}
  end

  # The flusher recursively calls itself on the specificed `interval`. This ensures
  # items do not sit in the buffer longer than `interval`.
  defp flusher(interval) do
    Process.send_after(self(), :flusher_step, interval)
  end

  @doc false
  @spec flush(t) :: t
  def flush(%{buffer: []} = state) do
    state
  end
  def flush(%{api_key: api_key, buffer: buffer} = state) do
    {:ok, body} =
      buffer
      |> Enum.map(&LogEntry.to_map!/1)
      |> Msgpax.pack()

    auth_token = Base.encode64(api_key)

    headers = %{
      "Authorization" => "Basic #{auth_token}",
      "Content-Type" => "application/msgpack",
      "User-Agent" => "Timber Elixir HTTP Transport/1.0.0"
    }

    get_http_client().request(:post, @url, headers, body, [])

    %{state | buffer: [], buffer_size: 0}
  end

  defp config, do: Application.get_env(:timber, :http_transport, [])

  defp get_http_client, do: Keyword.get(config(), :http_client, @default_http_client)
end
