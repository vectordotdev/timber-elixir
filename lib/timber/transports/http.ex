defmodule Timber.Transports.HTTP do
  @moduledoc """
  A highly efficient HTTP transport that buffers and delivers log messages over HTTP to the
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

  alias Timber.{LogEntry, LoggerBackend}

  defstruct api_key: nil,
            output: nil,
            buffer_size: 0,
            max_buffer_size: @default_max_buffer_size,
            buffer: []

  @typep t :: %__MODULE__{
    api_key: String.t,
    output: nil | IO.chardata,
    buffer_size: non_neg_integer,
    max_buffer_size: pos_integer,
    buffer: [] | [IO.chardata]
  }

  @default_max_buffer_size 100
  @default_http_client __MODULE__.HackneyClient
  @url "https://api.timber.io/frames"

  @doc false
  @spec init() :: {:ok, t}
  def init() do
    config()
    |> configure(%__MODULE__{})
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
  def write(%LogEntry{dt: timestamp, level: level, message: message} = log_entry, %{buffer: buffer, buffer_size: buffer_size}) do
    new_state = if buffer_size < max_buffer_size do
      write_buffer(log_entry, state)
    else
      flush(state)
    end

    {:ok, new_state}
  end

  # Writes a log entry into the buffer
  @spec write_buffer(LogEntry.t, t) :: t
  defp write_buffer(log_entry, %{buffer: buffer, buffer_size: buffer_size}) do
    %__MODULE__{state | buffer: [buffer | log_entry], buffer_size: buffer_size + 1}
  end

  def handle_info(_, state) do
    {:ok, state}
  end

  @doc false
  @spec flush(t) :: t
  def flush(%{buffer: []} = state), do: state
  def flush(%{api_key: api_key, buffer: buffer} = state) do
    body =
      buffer
      |> Enum.map(&LogEntry.to_map!/1)
      |> Msgpax.pack()

    auth_token = Base.encode64(api_key)

    headers = %{
      "Authorization" => "Basic #{auth_token}",
      "Content-Type" => "application/msgpack",
      "User-Agent" => "Timber Elixir HTTP Transport/1.0.0"
    }

    :hackney.request(:post, @url, headers, body, [with_body: true])

    %{state | buffer: [], buffer_size: 0}
  end

  # If there is an existing ref, that means we need to wait for
  # the IO device to inform us that it is done writing.
  def flush(state) do
    state
    |> wait_for_device()
    |> flush()
  end

  defp config, do: Application.get_env(:timber, :http_transport, [])

  defp get_http_client!, do: Keyword.get(config(), :http_client, @default_http_client)
end
