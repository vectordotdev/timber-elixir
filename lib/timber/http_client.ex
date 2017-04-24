defmodule Timber.HTTPClient do
  @moduledoc false

  @type body :: IO.chardata
  @type headers :: map
  @type method :: atom
  @type status :: pos_integer
  @type url :: String.t
  @type async_result :: {:ok, reference} | {:error, atom}
  @type result :: {:ok, integer, map, String.t} | {:error, atom}

  @callback start() :: :ok
  @callback async_request(method, url, headers, body) :: async_result
  @callback request(method, url, headers, body) :: result
end
