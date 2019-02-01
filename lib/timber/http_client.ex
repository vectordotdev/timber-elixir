defmodule Timber.HTTPClient do
  @moduledoc false

  @type body :: IO.chardata()
  @type headers :: map
  @type method :: atom
  @type status :: pos_integer
  @type url :: String.t()

  @callback async_request(method, url, headers, body) ::
              {:ok, reference}
              | {:error, atom}

  @callback request(method, url, headers, body) ::
              {:ok, integer, map, String.t()}
              | {:error, atom}
end
