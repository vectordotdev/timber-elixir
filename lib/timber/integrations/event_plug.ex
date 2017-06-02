defmodule Timber.Integrations.EventPlug do
  @moduledoc """
  Automatically logs metadata information about HTTP requests
  and responses in Plug-based frameworks like Phoenix.

  Whether you use Plug by itself or as part of a framework like Phoenix,
  adding this plug to your pipeline will automatically create events
  for incoming HTTP requests and responses for your log statements.

  Note: If you're using `Timber.Integrations.ContextPlug`, that plug should come before
  `Timber.Integrations.EventPlug` in any pipeline. This will give you the best results.

  ## Adding the Plug

  `Timber.Integrations.EventPlug` can be added to your plug pipeline using the standard
  `Plug.Builder.plug/2` macro. The point at which you place it determines
  what state Timber will receive the connection in, therefore it's
  recommended you place it as close to the origin of the request as
  possible.

  ### Plug (Standalone or Plug.Router)

  If you are using Plug without a framework, your setup will vary depending
  on your architecture. The call to `plug Timber.Integrations.EventPlug` should be grouped
  with any other plugs you call prior to performing business logic.

  Timber expects query paramters to have already been fetched on the
  connection using `Plug.Conn.fetch_query_params/2`.

  ### Phoenix

  Phoenix's flexibility means there are multiple points in the plug pipeline
  where the `Timber.Integrations.EventPlug` can be inserted. The recommended place is in
  a `:logging` pipeline in your router, but if you have more complex needs
  you can also place the plug in an endpoint or a controller.

  ```elixir
  defmodule MyApp.Router do
    use MyApp.Web, :router

    pipeline :logging do
      plug Timber.Integrations.EventPlug
    end

    scope "/api", MyApp do
      pipe_through :logging
    end
  end
  ```

  If you place the plug call in your endpoint, you will need to make sure
  that it appears after `Plug.RequestId` (if you are using it) but before
  the call to your router.

  ## Issues with Plug.ErrorHandler

  If you are using `Plug.ErrorHandler`, you will not see a response
  event if an exception is raised. This is because of how the error
  handler works in practice. In order to capture information about the
  response, Timber registers a callback to be used before Plug actually
  sends the response. Plug stores this information on the
  connection struct. When an exception is raised, the methodology used
  by the error handler will reset the conn to the state it was first
  accepted by the router.
  """

  #@behaviour Plug

  require Logger

  alias Timber.Events.{HTTPServerRequestEvent, HTTPServerResponseEvent}
  alias Timber.Timer
  alias Timber.Utils.Plug, as: PlugUtils

  @doc """
  Prepares the given options for use in a plug pipeline

  When the `Plug.Builder.plug/2` macro is called, it will use this
  function to prepare options. Any resulting options will be
  passed on to the plug on every call. The options accepted
  by this function are the same as defined by `call/2`.
  """
  @spec init(Plug.opts) :: Plug.opts
  def init(opts) do
    opts
  end

  @doc """
  Logs the HTTP request as soon as the Plug is called and will log
  the response when it is sent
  """
  @spec call(Plug.Conn.t, Plug.opts) :: Plug.Conn.t
  def call(conn, opts) do
    timer = Timer.start()
    log_level = Keyword.get(opts, :log_level, :info)
    request_id_header_name = Keyword.get(opts, :request_id_header, "x-request-id")
    request_id_header = PlugUtils.get_request_id(conn, request_id_header_name)
    request_id = request_id_from_header(request_id_header)

    method = conn.method
    host = conn.host
    port = conn.port
    scheme = conn.scheme
    path = conn.request_path
    headers = List.flatten([request_id_header | conn.req_headers])
    query_string = conn.query_string

    event = HTTPServerRequestEvent.new(
      body: conn.body_params, # the body is normalized and truncated if necessary
      headers: headers,
      host: host,
      method: method,
      path: path,
      port: port,
      query_string: query_string,
      request_id: request_id,
      scheme: scheme
    )

    message = HTTPServerRequestEvent.message(event)
    metadata = Timber.Utils.Logger.event_to_metadata(event)

    Logger.log(log_level, message, metadata)

    Plug.Conn.put_private(conn, :timber_opts, opts)
    |> Plug.Conn.put_private(:timber_timer, timer)
    |> Plug.Conn.register_before_send(&log_response_event/1)
  end

  @spec log_response_event(Plug.Conn.t) :: Plug.Conn.t
  defp log_response_event(conn) do
    time_ms = Timber.duration_ms(conn.private.timber_timer)
    opts = conn.private.timber_opts
    log_level = Keyword.get(opts, :log_level, :info)

    status = Plug.Conn.Status.code(conn.status)

    request_id_header_name = Keyword.get(opts, :request_id_header, "x-request-id")
    request_id_header = PlugUtils.get_request_id(conn, request_id_header_name)

    # The response body typing is iodata; it should not be assumed
    # to be a binary
    bytes = body_bytes(conn.resp_body)

    headers = [{"content-length", Integer.to_string(bytes)}, request_id_header | conn.resp_headers]

    request_id = request_id_from_header(request_id_header)

    event = HTTPServerResponseEvent.new(
      body: conn.resp_body, # the body is normalized and truncated if necessary
      headers: headers,
      request_id: request_id,
      status: status,
      time_ms: time_ms
    )

    message = HTTPServerResponseEvent.message(event)
    metadata = Timber.Utils.Logger.event_to_metadata(event)

    Logger.log(log_level, message, metadata)

    conn
  end

  defp body_bytes(nil), do: 0
  defp body_bytes(body), do: IO.iodata_length(body)

  defp request_id_from_header(request_id_header) do
    case request_id_header do
      [{_, request_id}] -> request_id
      [] -> nil
    end
  end
end
