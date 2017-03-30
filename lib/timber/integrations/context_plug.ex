defmodule Timber.Integrations.ContextPlug do
  @moduledoc """
  Automatically captures the HTTP method, path, and request_id in Plug-based frameworks
  like Phoenix and adds it to the context.

  By adding this data to the context, you'll be able to associate
  all the log statements that occur while processing that HTTP request.

  ## Adding the Plug

  `Timber.Integrations.ContextPlug` can be added to your plug pipeline using the standard
  `Plug.Builder.plug/2` macro. The point at which you place it determines
  what state Timber will receive the connection in, therefore it's
  recommended you place it as close to the origin of the request as
  possible.

  ### Plug (Standalone or Plug.Router)

  If you are using Plug without a framework, your setup will vary depending
  on your architecture. The call to `plug Timber.Integrations.ContextPlug` should be grouped
  with any other plugs you call prior to performing business logic.

  Timber expects query parameters to have already been fetched on the
  connection using `Plug.Conn.fetch_query_params/2`.

  ### Phoenix

  Phoenix's flexibility means there are multiple points in the plug pipeline
  where the `Timber.Integrations.ContextPlug` can be inserted. The recommended place is in
  `endpoint.ex`. Make sure that you insert this plug immediately before your `Router` plug.

  ## Request ID

  Timber does its best to track the request ID for every HTTP request
  in order to help you filter your logs responsibly. If you are calling
  the `Plug.RequestId` plug in your pipeline, you should make sure
  that `Timber.Integrations.ContextPlug` appears _after_ that plug so that it can pick
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

  alias Timber.Contexts.{HTTPContext, SessionContext}
  alias Timber.Utils.Plug, as: PlugUtils

  @session_id_key :_timber_session_id

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
  def call(%{method: method, request_path: request_path} = conn, opts) do
    session_id = get_session_id(conn)

    if session_id do
      %SessionContext{id: session_id}
      |> Timber.add_context()
    end

    request_id_header = Keyword.get(opts, :request_id_header, "x-request-id")
    remote_addr = PlugUtils.get_client_ip(conn)
    request_id =
      case PlugUtils.get_request_id(conn, request_id_header) do
        [{_, request_id}] -> request_id
        [] -> nil
      end

    %HTTPContext{
      method: method,
      path: request_path,
      request_id: request_id,
      remote_addr: remote_addr
    }
    |> Timber.add_context()

    conn
  end

  # Gets the session ID from the current connection.
  defp get_session_id(conn) do
    conn
    |> ensure_session_id()
    |> Plug.Conn.get_session(@session_id_key)
  rescue
    # Handles https://github.com/elixir-lang/plug/blob/master/lib/plug/conn.ex#L885
    e in ArgumentError -> nil
  end

  defp ensure_session_id(conn) do
    # Plug does not expose the actual id, so we need to make our own.
    # This should be fine as it is simply a unique identifier that is shared across
    # the context.
    conn = Plug.Conn.fetch_session(conn)
    existing_session_id = Plug.Conn.get_session(conn, @session_id_key)

    if !existing_session_id do
      Plug.Conn.put_session(conn, @session_id_key, generate_session_id())
    else
      conn
    end
  end

  defp generate_session_id do
    32
    |> :crypto.strong_rand_bytes()
    |> Base.encode16(case: :lower)
    |> binary_part(0, 32)
  end
end
