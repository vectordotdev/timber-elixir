defmodule Timber.Transports.HTTP do
  @moduledoc """
  An efficient HTTP transport that buffers and delivers log messages over HTTP to the
  Timber API. It uses batching, keep-alive connections, and msgpack to deliver logs with
  high-throughput and little overhead.

  The HTTP transport functions differently than a traditional buffer in that it is designed for
  batch delivery. This means messages are buffered by default and flushed on an internval.
  If the buffer size exceeds `:max_buffer_size` before the next intervaled flush, the buffer
  will be immediately flushed.

  All outgoing requests are made asynchronously. If a second request is made while the
  previous (first) request is still being processed, then the transport will enter
  synchronous mode, waiting for a response before proceeding with the request.

  ## Configuration

  ### Custom HTTP client

  By default, hackney is used via `Timber.Transports.HTTP.HackneyClient`. You can define your
  own custom HTTP client by adhering to the `Timber.Transports.HTTP.Client` behaviour. Afterwards,
  you must specify your client in the configuration:

  ```
  config :timber, :http_client, MyHTTPClient
  ```
  """

  @behaviour Timber.Transport

  alias Timber.Config
  alias Timber.LogEntry

  @type t :: %__MODULE__{
    api_key: String.t,
    buffer_size: non_neg_integer,
    buffer: buffer,
    flush_interval: non_neg_integer,
    max_buffer_size: pos_integer,
    ref: reference
  }
  @type buffer :: [] | [IO.chardata]

  @content_type "application/msgpack"
  @default_max_buffer_size 5000 # 5000 log line should be well below 5mb
  @default_flush_interval 1000
  @url "https://logs.timber.io/frames"

  defstruct api_key: nil,
            buffer_size: 0,
            buffer: [],
            flush_interval: @default_flush_interval,
            max_buffer_size: @default_max_buffer_size,
            ref: nil

  @doc false
  @spec init() :: {:ok, t} | {:error, atom}
  def init() do
    config = Keyword.put(config(), :api_key, Timber.Config.api_key!())

    with {:ok, state} <- configure(config, %__MODULE__{}),
         state <- outlet(state),
         do: {:ok, state}
  end

  @doc false
  @spec configure(Keyword.t, t) :: {:ok, t} | {:error, atom}
  def configure(options, %{api_key: current_api_key} = state) do
    api_key = Keyword.get(options, :api_key, current_api_key)
    max_buffer_size = Keyword.get(options, :max_buffer_size, @default_max_buffer_size)
    new_state = %{ state | api_key: api_key, max_buffer_size: max_buffer_size }

    if api_key == nil do
      {:error, :no_api_key}
    else
      {:ok, new_state}
    end
  end

  @doc false
  @spec flush(t) :: t
  def flush(state) do
    state
    |> issue_request()
    |> wait_on_request()
  end

  # Handle the outlet step, this recursively calls through process messaging via
  # `Process.send_after/3`. This is how the flush interval is maintained.
  @doc false
  @spec handle_info(atom(), t) :: {:ok, t}
  def handle_info(:outlet, state) do
    new_state =
      state
      |> issue_request()
      |> outlet()
    {:ok, new_state}
  end

  # Do nothing for everything else.
  def handle_info(_, state) do
    {:ok, state}
  end

  @doc false
  @spec write(LogEntry.t, t) :: {:ok, t}
  def write(log_entry, state) do
    # Write to the buffer immediately because we want to batch lines and send
    # them on an interval.
    state = write_buffer(log_entry, state)

    if buffer_full?(state) do
      # The buffer is full, flush immediately.
      {:ok, flush(state)}
    else
      {:ok, state}
    end
  end

  # Writes a log entry into the buffer
  @spec write_buffer(LogEntry.t, t) :: t
  defp write_buffer(log_entry, %{buffer: buffer, buffer_size: buffer_size} = state) do
    %{state | buffer: [log_entry | buffer], buffer_size: buffer_size + 1}
  end

  # The outlet recursively calls itself through process messaging via `Process.send_after/3`.
  # This allows us to clear the buffer on an interval ensuring messages are delivered, at most,
  # by the specified interval length.
  @spec outlet(t) :: t
  defp outlet(%{flush_interval: flush_interval} = state) do
    Process.send_after(self(), :outlet, flush_interval)
    state
  end

  # Waits for the async request to complete
  @spec wait_on_request(t) :: t
  defp wait_on_request(%{ref: nil} = state) do
    state
  end

  defp wait_on_request(%{ref: ref}) do
    Config.http_client!().wait_on_request(ref)
  end

  # Delivers the buffer contents to Timber asynchronously using the provided HTTP client.
  # Asynchronous requests are required so that we do not block the caller and provide
  # back pressure needlessly.
  @spec issue_request(t) :: t
  defp issue_request(%{buffer: []} = state) do
    state
  end

  defp issue_request(%{api_key: api_key, buffer: buffer} = state) do
    body = buffer_to_msg_pack(buffer)
    auth_token = Base.encode64(api_key)
    vsn = Application.spec(:timber, :vsn)
    user_agent = "Timber Elixir/#{vsn} (HTTP)"

    headers =
      %{
        "Authorization" => "Basic #{auth_token}",
        "Content-Type" => @content_type,
        "User-Agent" => user_agent
      }

    url = Config.http_url() || @url

    case Config.http_client!().async_request(:post, url, headers, body) do
      {:ok, ref} ->
        new_buffer = clear_buffer(state)
        %{ new_buffer | ref: ref }

      {:error, _reason} ->
        # If the buffer is full and we can't send the request, drop the messages.
        if buffer_full?(state) do
          clear_buffer(state)
        else
          # Ignore errors, keep the buffer, and allow the next attempt to retry.
          state
        end
    end
  end

  @spec buffer_full?(t) :: boolean
  defp buffer_full?(state) do
    state.buffer_size >= state.max_buffer_size
  end

  @spec clear_buffer(t) :: t
  defp clear_buffer(state) do
    %{ state | buffer: [], buffer_size: 0 }
  end

  # Encodes the buffer into msgpack
  @spec buffer_to_msg_pack(buffer) :: IO.chardata
  defp buffer_to_msg_pack(buffer) do
    buffer
    |> Enum.reverse()
    |> Enum.map(&LogEntry.to_map!/1)
    |> Enum.map(&prepare_for_msgpax/1)
    |> Msgpax.pack!()
  end

  # Normalizes the LogEntry.message into a string if it is not.
  @spec prepare_for_msgpax(LogEntry.t) :: LogEntry.t
  defp prepare_for_msgpax(%{message: nil} = log_entry), do: log_entry

  defp prepare_for_msgpax(log_entry_map) do
    Map.put(log_entry_map, :message, IO.chardata_to_string(log_entry_map.message))
  end

  #
  # Config
  #

  @spec config() :: Keyword.t
  defp config, do: Application.get_env(:timber, :http_transport, [])
end
