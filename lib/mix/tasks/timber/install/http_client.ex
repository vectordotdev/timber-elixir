defmodule Mix.Tasks.Timber.Install.HTTPClient do
  alias __MODULE__.{BadResponseError, InvalidAPIKeyError, MalformedAPIResponseError}
  alias Mix.Tasks.Timber.Install.Messages

  @api_url "https://api.timber.io"

  # This is rather crude way of making HTTP requests, but it beats requiring an HTTP client
  # as a dependency just for this installer.
  def request!("GET", path, api_key) do
    url = @api_url <> path
    encoded_api_key = Base.encode64(api_key)
    flags = ["-s", "-H", "Authorization: Basic #{encoded_api_key}", "-w", " _STATUS_:%{http_code}", url]
    {response, _} = System.cmd("curl", flags)

    case String.split(response, " _STATUS_:", parts: 2) do
      [body, status_str] ->
        case Integer.parse(status_str) do
          {status, _units} when status in 200..299 ->
            case Poison.decode(body) do
              {:ok, %{"data" => data}} -> data
              _other -> raise(MalformedAPIResponseError, url: url, response: response)
            end

          {403, _units} -> raise(InvalidAPIKeyError)

          _other -> raise(BadResponseError, url: url, response: response)
        end

      _result -> raise(MalformedAPIResponseError, url: url, response: response)
    end
  end

  #
  # Errors
  #

  defmodule BadResponseError do
    defexception [:message]

    def exception(opts) do
      url = Keyword.fetch!(opts, :url)
      response = Keyword.fetch!(opts, :response)

      message =
        """
        Uh oh! We got a bad response from #{url}.
        The response received was:

        #{response}
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
      response = Keyword.fetch!(opts, :response)
      message =
        """
        We received a malformed response from #{url}.
        The response we received was:

        #{inspect(response)}

        Please try again.
        """
      %__MODULE__{message: message}
    end
  end
end