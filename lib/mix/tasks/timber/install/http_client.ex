defmodule Mix.Tasks.Timber.Install.HTTPClient do
  alias __MODULE__.{BadResponseError, InvalidAPIKeyError, MalformedAPIResponseError}
  alias Mix.Tasks.Timber.Install.Messages

  @api_url "https://api.timber.io"

  def start do
    case :inets.start() do
      :ok -> :ok
      {:error, {:already_started, _name}} -> :ok
      other -> other
    end
  end

  # This is rather crude way of making HTTP requests, but it beats requiring an HTTP client
  # as a dependency just for this installer.
  def request!(method, path, api_key) when method in [:get] do
    url = @api_url <> path
    encoded_api_key = Base.encode64(api_key)
    headers = [{'Authorization', 'Basic #{encoded_api_key}'}]
    case :httpc.request(method, {String.to_charlist(url), headers}, [], []) do
      {:ok, {{_protocol, status, _status_name}, _headers, body}} ->
        case status do
          value when value in 200..299 ->
            {status, decode_body("#{body}", url)}

          403 -> raise(InvalidAPIKeyError)

          value -> raise(BadResponseError, url: url, body: body, status: value)
        end

      {:error, reason} -> raise(CommunicationError, url: url, reason: reason)
    end
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