defmodule Timber.Integrations.ExAwsHTTPClient do
  @moduledoc """
  [ExAWS](https://github.com/CargoSense/ex_aws) is an excellent library for interfacing with the
  AWS API. The Timber `ExAWSHTTPClient` adds structured logging to the HTTP requests being
  sent to the AWS API. This gives you valuable insight into AWS communication from your application.
  We use is internally at Timber.

  **By default**, this library will only log destructive requests (`POST`, `PUT`, `DELETE`,
  and `PATCH`). `GET` requests can be turned via configuration (see below).

  ## Installation

  ```elixir
  config :ex_aws,
    http_client: Timber.Integrations.ExAwsHTTPClient
  ```

  ## Configuration

  ```elixir
  config :timber, Timber.Integrations.ExAWSHTTPClient,
    log_destructive_requests_only: true
  ```

  * `log_destructive_requests_only` - (default: `true`) Only log `POST`, `PUT`, `DELETE`,
    and `PATCH` requests.
  """

  alias Timber.Events.HTTPRequestEvent
  alias Timber.Events.HTTPResponseEvent

  require Logger

  # Set a timeout slightly over the general AWS timeout. This ensures that we receive
  # the timeout event from AWS before we receive it internally, preventing orphaned requests.
  @default_opts [recv_timeout: 62_000]
  @destructive_methods [:patch, :post, :put, :delete]
  @service_name :aws

  def request(method, url, body \\ "", headers \\ [], http_opts \\ []) do
    opts =
      :ex_aws
      |> Application.get_env(:hackney_opts, @default_opts)
      |> Keyword.merge(http_opts)
      |> Keyword.put(:with_body, true)

    timer = Timber.start_timer()
    should_log = should_log?(method, log_destructive_requests_only?())
    log_request(should_log, method, url, body, headers)

    case :hackney.request(method, url, headers, body, opts) do
      {:ok, status, headers} ->
        log_response(should_log, status, headers, timer)
        {:ok, %{status_code: status, headers: headers}}

      {:ok, status, headers, body} ->
        log_response(should_log, status, headers, timer, body: body)
        {:ok, %{status_code: status, headers: headers, body: body}}

      {:error, reason} ->
        # Errors are not logged because they should be handled. It is up
        # to the caller to log these properly.
        {:error, %{reason: reason}}
    end
  end

  defp should_log?(method, true) when method in @destructive_methods,
    do: true

  defp should_log?(_method, _log_destructive_requests_only),
    do: true

  defp log_request(false, _method, _url, _body, _headers),
    do: nil

  defp log_request(true, method, url, body, headers) do
    Logger.info fn ->
      event =
        HTTPRequestEvent.new(
          direction: "outgoing",
          method: method,
          url: url,
          body: body,
          headers: headers,
          service_name: @service_name
        )
      message = HTTPRequestEvent.message(event)
      {message, event: event}
    end
  end

  defp log_response(should_log, status, headers, timer, opts \\ [])

  defp log_response(false, _status, _headers, _timer, _opts),
    do: nil

  defp log_response(true, status, headers, timer, opts) do
    Logger.info fn ->
      time_ms = Timber.duration_ms(timer)
      body = Keyword.get(opts, :body)
      event =
        HTTPResponseEvent.new(
          direction: "incoming",
          body: body,
          status: status,
          headers: headers,
          service_name: @service_name,
          time_ms: time_ms
        )
      message = HTTPResponseEvent.message(event)
      {message, event: event}
    end
  end

  #
  # Config
  #

  defp config, do: Elixir.Application.get_env(:timber, __MODULE__, [])
  defp log_destructive_requests_only?, do: Keyword.get(config(), :log_destructive_requests_only, true) == true
end