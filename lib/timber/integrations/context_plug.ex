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
    conn = initialize_session_id(conn)

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

  @spec initialize_session_id(Plug.Conn.t) :: Plug.Conn.t
  # Attempts to retrieve or initialize the Timber session ID.
  #
  # Timber assigns a unique, 32 character ID to every session. Once assigned, Timber
  # is able to retrieve it for the duration of the session, so even on subsequent
  # requests, the session ID remains the same.
  #
  # The session ID is then added to the Timber context as a side-effect. This prevents
  # it being added if sessions are not being used.
  #
  # In order to retrieve the session, the session plug must already have been
  # defined. If it hasn't been, fetching the session will cause an `ArgumentError`
  # exception to be raised. In this case, the exception is rescued and the
  #
  defp initialize_session_id(conn) do
    # We make sure the session has been fetched and loaded onto the conn. This call has
    # the chance to raise if Plug doesn't have an adapter for sessions. If that's the
    # case, the exception is rescued in the `rescue` section below.
    session_conn = Plug.Conn.fetch_session(conn)
    # Now that we've confirmed a session is loaded, we try to retrieve the session ID
    # from Timber's custom session key. If this doesn't exist, we generate one.
    #
    # We make sure to put the session_id on the session at the end of this function,
    # so we don't concern ourselves with that here.
    session_id =
      case Plug.Conn.get_session(session_conn, @session_id_key) do
        nil ->
          generate_session_id()
        id ->
          id
      end

    # We set up the session context and assign it to the Timber context here.
    # This is the safest place to do it, since we've confirmed that the session is
    # being used and a session ID has been generated. This is a side-effect, and we
    # don't return anything about it to the caller function.
    %SessionContext{id: session_id}
    |> Timber.add_context()

    # We ensure that we set the session_id on the session here, regardless of whether
    # it was set before. This change is idempotent if it was already present.
    Plug.Conn.put_session(session_conn, @session_id_key, session_id)
  rescue
    ArgumentError ->
      # If no session Plug has been defined, the call to `Plug.Conn.fetch_session/1`
      # will raise an ArgumentError. In this case, we return the original conn
      # from the function parameters
      conn
  end

  defp generate_session_id do
    32
    |> :crypto.strong_rand_bytes()
    |> Base.encode16(case: :lower)
    |> binary_part(0, 32)
  end
end
