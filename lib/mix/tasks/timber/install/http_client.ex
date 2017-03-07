defmodule Mix.Tasks.Timber.Install.HTTPClient do
  alias Mix.Tasks.Timber.Install.Messages

  @api_url "https://api.timber.io"

  @communication_error_message \
    """
    We're having trouble connecting to #{@api_url}. Please ensure that
    this computer can connect to this URL. This is neccessary to verify
    your API key and test installation.
    """

  @malformed_response_error_message \
    """
    We're having trouble communicating with the Timber API.
    The response sent back was malformed :(
    """

  # This is rather crude way of making HTTP requests, but it beats requiring an HTTP client
  # as a dependency just for this installer.
  def request("GET", path, headers) do
    header_flags = Enum.map(headers, fn {key, val} -> "-H \"#{key}: #{val}\"" end)
    url = @api_url <> path
    flags = header_flags ++ ["-s", "-w _STATUS_:%{http_code}", url]
    {response, _} = System.cmd("curl", flags)

    case String.split(response, " _STATUS_:", parts: 2) do
      [body, status_str] ->
        case Integer.parse(status_str) do
          {status, _units} when status in 200..299 ->
            case Poison.decode(body) do
              {:ok, %{"data" => data}} -> {:ok, data}
              {:error, _reason} -> {:error, @malformed_response_error_message}
              {:error, _reason, _position} -> {:error, @malformed_response_error_message}
            end

          {403, _units} -> {:error, invalid_api_key_message()}

          {status, _units} -> {:error, @communication_error_message <> "Response status: #{status}"}

          :error -> {:error, @communication_error_message}
        end

      _ -> {:error, @communication_error_message}
    end
  end

  defp invalid_api_key_message do
    """
    Uh oh! It looks like the API key you provided is invalid :(
    Please ensure that you copied the key properly.

    #{Messages.obtain_key_instructions()}

    #{Messages.get_help()}
    """
  end
end