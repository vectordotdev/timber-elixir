  defmodule Timber.InvalidAPIKeyError do
    @moduledoc """
    Raised when Timber rejects the provided API key
    """

    defexception [:message]

    @doc false
    def exception(opts) do
      api_key = Keyword.get(opts, :api_key)
      status = Keyword.get(opts, :status)

      message = """
      The Timber service does not recognize your API key. Please check
      that you have specified your key correctly.

        config :timber, api_key: "my_timber_api_key"

      You can locate your API key in the Timber console by creating or
      editing your app: https://app.timber.io

      Debug info:
      API key: #{api_key}
      Status from the Timber API: #{status}
      """

      %__MODULE__{message: message}
    end
  end
