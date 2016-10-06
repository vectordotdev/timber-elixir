defmodule Timber do
  @moduledoc """
  The functions in this module work by modifying the Logger metadata store which
  is unique to every BEAM process. This is convenient in many ways. First and
  foremost, it does not require you to manually manage the metadata. Second,
  because we conform to the standard Logger principles, you can utilize Timber
  alongside other Logger backends without issue. Timber prefixes its contextual
  metadata keys so as not to interfere with other systems.

  ## The Context Stack
  """

  alias Timber.Contexts
  alias Timber.ContextEntry

  @doc """
  Adds a custom context entry to the context stack. This is typically used if you have a
  specific context you want to be displayed in Timber that is not one of the
  commonly supported contexts.
  """
  @spec add_custom_context(String.t, %{String.t => any}) :: :ok
  def add_custom_context(name, data) do
    c = %Contexts.CustomContext{
      name: name,
      data: data
    }

    add_context_entry(:custom, c)
  end

  @doc """
  Adds an exception context to the context stack. It's unlikely you will have to call this
  manually; Timber hooks into the SASL reporting system to collect exception information.
  """
  @spec add_exception_context(String.t, String.t, [String.t]) :: :ok
  def add_exception_context(name, message, backtrace) do
    c = %Contexts.ExceptionContext{
      name: name,
      message: message,
      backtrace: backtrace
    }

    add_context_entry(:exception, c)
  end

  @doc """
  Adds an HTTP request context to the context stack. If you use a Plug-based system, it is
  recommended you use the provided `Timber.Plug` to handle Plug logging. If you use a
  custom set-up, you should call `add_http_request_context/7` when a new HTTP request
  is received.
  """
  @spec add_http_request_context(
    String.t,
    pos_integer,
    String.t,
    Contexts.HTTPRequestContext.method,
    String.t,
    [Contexts.HTTPRequestContext.header],
    %{String.t => String.t}
  ) :: :ok
  def add_http_request_context(host, port, scheme, method, path, headers, query_params) do
    c = %Contexts.HTTPRequestContext{
      host: host,
      port: port,
      scheme: scheme,
      method: method,
      path: path,
      headers: headers,
      query_params: query_params
    }

    add_context_entry(:http_request, c)
  end

  @doc """
  Adds an HTTP response context to the context stack. If you use a Plug-based system, it is
  recommended you use the provided `Timber.Plug` to handle Plug logging. If you use a
  custom set-up, you should call `add_http_response_context/3` when an HTTP response
  is sent to the client.
  """
  @spec add_http_response_context(
    non_neg_integer,
    [Contexts.HTTPResponseContext.header],
    pos_integer
  ) :: :ok
  def add_http_response_context(bytes, headers, status) do
    c = %Contexts.HTTPResponseContext{
      bytes: bytes,
      headers: headers,
      status: status
    }

    add_context_entry(:http_response, c)
  end

  @doc """
  Adds an organization context to the context stack. You will want to add this context at
  the time you determine a user's organization, probably at the same time you determine
  the user.
  """
  @spec add_organization_context(String.t, String.t) :: :ok
  def add_organization_context(id, name) do
    c = %Contexts.OrganizationContext{
      id: id,
      name: name
    }

    add_context_entry(:organization, c)
  end

  @doc """
  Adds a SQL query context to the context stack. If you use Ecto, it is recommended you add
  `Timber.Ecto.Logger` as an Ecto logger to handle this automatically.
  """
  @spec add_sql_query_context(String.t, float, %{String.t => String.t}) :: :ok
  def add_sql_query_context(sql, time_ms, binds) do
    c = %Contexts.SQLQueryContext{
      sql: sql,
      time_ms: time_ms,
      binds: binds
    }

    add_context_entry(:sql_query, c)
  end

  @doc """
  Adds a server context to the context stack.
  """
  @spec add_server_context(String.t) :: :ok
  def add_server_context(hostname) do
    c = %Contexts.ServerContext{
      hostname: hostname
    }

    add_context_entry(:server, c)
  end

  @doc """
  Adds a template render context to the context stack.
  """
  @spec add_template_render_context(String.t, float) :: :ok
  def add_template_render_context(name, time_ms) do
    c = %Contexts.TemplateRenderContext{
      name: name,
      time_ms: time_ms
    }

    add_context_entry(:template_render, c)
  end

  @doc """
  Adds a user context to the context stack.
  """
  @spec add_user_context(String.t, String.t, String.t) :: :ok
  def add_user_context(id, name, email) do
    c = %Contexts.UserContext{
      id: id,
      name: name,
      email: email
    }

    add_context_entry(:user, c)
  end

  @spec add_context_entry(ContextEntry.context_type, ContextEntry.context_data) :: :ok
  defp add_context_entry(type, data) do
    c = ContextEntry.new(Timber.Utils.now(), type, data)

    current_metadata = Elixir.Logger.metadata()
    current_context = Keyword.get(current_metadata, :timber_context, [])
    new_context = current_context ++ [c]

    Elixir.Logger.metadata([timber_context: new_context])
  end
end
