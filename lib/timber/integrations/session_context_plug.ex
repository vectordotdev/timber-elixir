defmodule Timber.Integrations.SessionContextPlug do
  @moduledoc """
  Automatically tracks the session in Plug-based frameworks like Phoenix
  and adds it to the context

  The session context plug is only useful if you have session storage already
  setup. More information about this can be found in the documentation for the
  specific framework you're using:

    - [Phoenix](http://www.phoenixframework.org/docs/sessions)
    - [Plug](https://hexdocs.pm/plug/Plug.Session.html)

  If you have chosen to not use sessions for your application, it's best not
  to use this plug. Using this plug without properly setting up a session store
  can cause HTTP responses to fail.

  ## Adding the Plug

  `Timber.Integrations.SessionContextPlug` can be added to your plug pipeline using the
  standard `Plug.Builder.plug/2` macro. Because it requires access to the session, it should
  be listed _after_ setting up the session store. The session store will usually be set up
  using a call to `plug Plug.Session`.
  """

  @session_id_key :_timber_session_id

  alias Timber.Contexts.SessionContext

  @doc """
  Prepares the given options for use in a plug pipeline

  When the `Plug.Builder.plug/2` macro is called, it will use this
  function to prepare options. Any resulting options will be
  passed on to the plug on every call. The options accepted
  by this function are the same as defined by `call/2`.
  """
  @spec init(Plug.opts()) :: Plug.opts()
  def init(opts) do
    opts
  end

  @doc """
  Adds the Request ID to the Timber context data
  """
  @spec call(Plug.Conn.t(), Plug.opts()) :: Plug.Conn.t()
  def call(conn, _opts) do
    initialize_session_id(conn)
  end

  @spec initialize_session_id(Plug.Conn.t()) :: Plug.Conn.t()
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
