defmodule Timber.Plug do
  @moduledoc """
  Automatically captures context information about HTTP requests
  and responses in Plug-based frameworks like Phoenix.

  Whether you use Plug by itself or as part of a framework like Phoenix,
  adding this plug to your pipeline will automatically add context
  information about HTTP requests and responses to your log statements.

  ## Adding the Plug

  `Timber.Plug` can be added to your plug pipeline using the standard
  `Plug.Builder.plug/2` macro. The point at which you place it determines
  what state Timber will receive the connection in, therefore it's
  recommended you place it as close to the origin of the request as
  possible.

  ### Plug (Standalone or Plug.Router)

  If you are using Plug without a framework, your setup will vary depending
  on your architecture. The call to `plug Plug.Timber` should be grouped
  with any other plugs you call prior to performing business logic.

  Timber expects query paramters to have already been fetched on the
  connection using `Plug.Conn.fetch_query_params/2`.

  ### Phoenix

  Phoenix's flexibility means there are multiple points in the plug pipeline
  where the `Timber.Plug` can be inserted. The recommended place is in
  a `:logging` pipeline in your router, but if you have more complex needs
  you can also place the plug in an endpoint or a controller.

  ```elixir
  defmodule MyApp.Router do
    use MyApp.Web, :router

    pipeline :logging do
      plug Timber.Plug
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
  that `Timber.Plug` appears _after_ that plug so that it can pick
  up the correct ID.

  By default, Timber expects your request ID to be stored using the
  header name "X-Request-ID" (casing irrelevant), but that may not
  fit all needs. If you use a custom header name for your request ID,
  you can pass that name as an option to the plug:

  ```
  plug Timber.Plug, request_id_header: "req-id"
  ```

  ## Issues with Plug.ErrorHandler

  If you are using `Plug.ErrorHandler`, you will lose any context regarding
  the response if an exception is raised. This is because of how the error
  handler works in practice. In order to capture information about the
  response, Timber registers a callback to be used before Plug actually
  sends the response. Plug stores this context information on the
  connection struct. When an exception is raised, the methodology used
  by the error handler will reset the conn to the state it was first
  accepted. This means the conn loses any changes made to it by your
  plug pipeline, including the callback Timber registered.
  """

  @behaviour Plug

  alias Timber.Contexts.{HTTPRequestContext, HTTPResponseContext}

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
  Adds contextual data about the request and response for this `conn` to
  Timber's context stack

  When this plug is called, information about the request is immediately
  added to the stack. 
  """
  @spec call(Plug.Conn.t, Plug.opts) :: Plug.Conn.t
  def call(conn, opts) do
    request_id_header = Keyword.get(opts, :request_id_header, "x-request-id")
    request_id = get_request_id(conn, request_id_header)

    headers_with_request_id = request_id ++ conn.req_headers

    host = conn.host
    port = conn.port
    scheme = conn.scheme
    path = conn.request_path
    headers = HTTPRequestContext.headers_from_list(headers_with_request_id)
    query_params = conn.query_params

    method =
      conn.method
      |> String.downcase()
      |> String.to_existing_atom()

    context = %HTTPRequestContext{
      host: host,
      port: port,
      scheme: scheme,
      method: method,
      path: path,
      headers: headers,
      query_params: query_params
    }

    Timber.add_context(context)

    Plug.Conn.put_private(conn, :timber_opts, opts)
    |> Plug.Conn.register_before_send(&add_response_context/1)
  end

  @spec add_response_context(Plug.Conn.t) :: Plug.Conn.t
  defp add_response_context(conn) do
    bytes = :erlang.byte_size(conn.resp_body)
    status = Plug.Conn.Status.code(conn.status)
    headers = HTTPResponseContext.headers_from_list(conn.resp_headers)

    context = %HTTPResponseContext{
      bytes: bytes,
      headers: headers,
      status: status
    }

    Timber.add_context(context)

    conn
  end

  # Fetches the request ID from the connection using the given header name
  #
  # The request ID may be added to the connection in a number of ways which
  # complicates how we retrieve it. It is usually set by calling the
  # Plug.RequestId module on the connection which sets a request ID only
  # if one hasn't already been set. If the request ID is set by a service
  # prior to Plug, it will be present as a request header. If Plug.RequestId
  # generates a request ID, that request ID is only present in the response
  # headers. The request headers should always take precedent in
  # this function, though.
  #
  # This function will return either a single element list containing a two-element
  # tuple of the form:
  #
  #   {"x-request-id", "myrequestid91391"}
  #
  # or an empty list. This normalizes the expectation of the header name for
  # future processing.
  #
  # Note: Plug.RequestId will change an existing request ID if
  # it doesn't think the request ID is valid. See
  # https://github.com/elixir-lang/plug/blob/v1.2.2/lib/plug/request_id.ex#L62
  @spec get_request_id(Plug.Conn.t, String.t) :: [{String.t, String.t}] | []
  defp get_request_id(conn, header_name) do
    case Plug.Conn.get_req_header(conn, header_name) do
      [] -> Plug.Conn.get_resp_header(conn, header_name)
      values -> values
    end
    |> handle_request_id()
  end

  # Helper function to take the result of the header retrieval function
  # and change it to the desired response format for get_request_id/2
  @spec handle_request_id([] | [String.t]) :: [{String.t, String.t}] | []
  defp handle_request_id([]) do
    []
  end

  defp handle_request_id([request_id | _]) do
    [{"x-request-id", request_id}]
  end
end
