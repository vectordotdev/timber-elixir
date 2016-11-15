defmodule Timber.ContextPlug do
  @moduledoc """
  Automatically captures the HTTP request ID in Plug-based frameworks
  like Phoenix and adds it to the context.

  By adding the request ID to the context, you'll be able to associate
  all the log statements that occur while processing that HTTP request.

  ## Adding the Plug

  `Timber.ContextPlug` can be added to your plug pipeline using the standard
  `Plug.Builder.plug/2` macro. The point at which you place it determines
  what state Timber will receive the connection in, therefore it's
  recommended you place it as close to the origin of the request as
  possible.

  ### Plug (Standalone or Plug.Router)

  If you are using Plug without a framework, your setup will vary depending
  on your architecture. The call to `plug Timber.ContextPlug` should be grouped
  with any other plugs you call prior to performing business logic.

  Timber expects query paramters to have already been fetched on the
  connection using `Plug.Conn.fetch_query_params/2`.

  ### Phoenix

  Phoenix's flexibility means there are multiple points in the plug pipeline
  where the `Timber.ContextPlug` can be inserted. The recommended place is in
  a `:logging` pipeline in your router, but if you have more complex needs
  you can also place the plug in an endpoint or a controller.

  ```elixir
  defmodule MyApp.Router do
    use MyApp.Web, :router

    pipeline :logging do
      plug Timber.ContextPlug
    end

    scope "/api", MyApp do
      pipe_through :logging
    end
  end
  ```

  If you place the plug call in your endpoint, you will need to make sure
  that it appears after `Plug.RequestId` (if you are using it) but before
  the call to your router.

  ## Request ID

  Timber does its best to track the request ID for every HTTP request
  in order to help you filter your logs responsibly. If you are calling
  the `Plug.RequestId` plug in your pipeline, you should make sure
  that `Timber.ContextPlug` appears _after_ that plug so that it can pick
  up the correct ID.

  By default, Timber expects your request ID to be stored using the
  header name "X-Request-ID" (casing irrelevant), but that may not
  fit all needs. If you use a custom header name for your request ID,
  you can pass that name as an option to the plug:

  ```
  plug Timber.Plug, request_id_header: "req-id"
  ```
  """

  require Logger

  alias Timber.Contexts.HTTPContext
  alias Timber.PlugUtils

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
  Adds the Request ID to the Timber context data
  """
  @spec call(Plug.Conn.t, Plug.opts) :: Plug.Conn.t
  def call(conn, opts) do
    request_id_header = Keyword.get(opts, :request_id_header, "x-request-id")
    remote_addr = PlugUtils.get_client_ip(conn)
    method = conn.method
    path = conn.path
    request_id =
      case PlugUtils.get_request_id(conn, request_id_header) do
        [{_, request_id}] -> request_id
        [] -> nil
      end

    %HTTPContext{
      method: method,
      path: path,
      request_id: request_id,
      remote_addr: remote_addr
    }
    |> Timber.add_context()

    conn
  end
end
