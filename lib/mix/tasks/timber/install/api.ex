defmodule Mix.Tasks.Timber.Install.API do
  @moduledoc false

  alias __MODULE__.{InvalidAPIKeyError, BadResponseError, CommunicationError,
    MalformedAPIResponseError}
  alias Mix.Tasks.Timber.Install.{Config, IOHelper, Messages}

  @enforce_keys [:api_key, :session_id]
  defstruct [:api_key, :session_id]

  #
  # Setup
  #

  def start do
    Config.http_client().start()
  end

  def new(api_key) do
    session_id =
      32
      |> :crypto.strong_rand_bytes()
      |> Base.encode16(case: :lower)
      |> binary_part(0, 32)

    %__MODULE__{api_key: api_key, session_id: session_id}
  end

  #
  # Endpoints
  #

  def application!(api) do
    request!(api, :get, "/installer/application")
  end

  def event!(api, name, data \\ nil) do
    request!(api, :post, "/installer/events", body: %{event: %{name: name, data: data}})
  end

  def has_logs!(api) do
    request!(api, :get, "/installer/has_logs")
  end

  def has_logs?(api) do
    case has_logs!(api) do
      {204, _body} -> true
      _ -> false
    end
  end

  def wait_for_logs(api, iteration \\ 0)

  def wait_for_logs(api, iteration) do
    excessive_threshold = 30

    cond do
      iteration == 0 -> event!(api, :waiting_for_logs)
      iteration == excessive_threshold -> event!(api, :excessive_log_waiting)
      true -> :ok
    end

    IO.ANSI.format(["\r", :clear_line])
    |> IOHelper.write()

    Messages.waiting_for_logs()
    |> Messages.action_starting()
    |> IOHelper.write()

    case has_logs!(api) do
      {202, _body} ->
        rem = rem(iteration, 3)

        Messages.spinner(rem)
        |> IOHelper.write()

        if iteration > excessive_threshold do
          " (Having trouble? We'd love to help: support@timber.io)"
          |> IOHelper.write()
        end

        :timer.sleep(1000)

        wait_for_logs(api, iteration + 1)

      {204, _body} ->
        Messages.success()
        |> IOHelper.puts(:green)

        :ok
    end
  end

  #
  # Utility
  #

  defp request!(%{api_key: api_key, session_id: session_id}, method, path, opts \\ []) do
    headers =
      [{'X-Installer-Session-Id', String.to_charlist(session_id)}]
      |> add_authorization_header(api_key)
    url = Config.api_url() <> path

    case Config.http_client().request(method, headers, url, opts) do
      {:ok, status, body} when status in 200..299 ->
        {status, decode_body("#{body}", url)}

      {:ok, status, _body} when status in [401, 403] -> raise(InvalidAPIKeyError)

      {:ok, status, body} -> raise(BadResponseError, url: url, body: body, status: status)

      {:error, reason} -> raise(CommunicationError, url: url, reason: reason)
    end
  end

  defp add_authorization_header(headers, nil), do: headers

  defp add_authorization_header(headers, api_key) do
    encoded_api_key = Base.encode64(api_key)
    [{'Authorization', 'Basic #{encoded_api_key}'} | headers]
  end

  defp decode_body("", _url), do: ""

  defp decode_body(body, url) do
    case Poison.decode(body) do
      {:ok, %{"data" => data}} -> data
      _other -> raise(MalformedAPIResponseError, url: url, body: body)
    end
  end

  #
  # Errors
  #

  defmodule BadResponseError do
    defexception [:message]

    def exception(opts) do
      url = Keyword.fetch!(opts, :url)
      body = Keyword.fetch!(opts, :body)
      status = Keyword.fetch!(opts, :status)

      message =
        """
        Uh oh! We got a bad response (#{status}) from #{url}.
        The response received was:

        #{body}
        """
      %__MODULE__{message: message}
    end
  end

  defmodule CommunicationError do
    defexception [:message]

    def exception(opts) do
      url = Keyword.fetch!(opts, :url)
      error = Keyword.fetch!(opts, :error)

      message =
        """
        Uh oh! We encountered an error communicating with #{url}.
        The error is:

        #{error}
        """
      %__MODULE__{message: message}
    end
  end

  defmodule InvalidAPIKeyError do
    defexception [:message]

    def exception(_opts) do
      message =
        """
        Uh oh! The API key supplied is invalid. Please ensure
        that you copied the key properly.

        #{Messages.obtain_key_instructions()}
        """
      %__MODULE__{message: message}
    end
  end

  defmodule MalformedAPIResponseError do
    defexception [:message]

    def exception(opts) do
      url = Keyword.fetch!(opts, :url)
      body = Keyword.fetch!(opts, :body)
      message =
        """
        We received a malformed response from #{url}.
        The response we received was:

        #{inspect(body)}

        Please try again.
        """
      %__MODULE__{message: message}
    end
  end
end
