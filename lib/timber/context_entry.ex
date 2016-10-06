defmodule Timber.ContextEntry do
  @moduledoc """
  The ContextEntry module formalizes the structure of context stack entries

  Most users will not interact directly with this module and will instead use
  the helper functions provided by the main `Timber` module. See the `Timber`
  module for more information.
  """

  alias Timber.Contexts
  alias Timber.Logger

  @type context_data ::
    Contexts.CustomContext.t |
    Contexts.ExceptionContext.t |
    Contexts.HTTPRequestContext.t |
    Contexts.HTTPResponseContext.t |
    Contexts.OrganizationContext.t |
    Contexts.SQLQueryContext.t |
    Contexts.ServerContext.t |
    Contexts.TemplateRenderContext.t |
    Contexts.UserContext.t

  @type context_type ::
    :custom |
    :exception |
    :http_request |
    :http_response |
    :organization |
    :sql_query |
    :server |
    :template_render |
    :user

  @type t :: %__MODULE__{
    dt: String.t,
    index: non_neg_integer,
    type: context_type,
    data: context_data
  }

  defstruct [:type, :dt, :type, :data, index: 0]

  @doc """
  Creates a new context entry for a context stack

  The `type` passed should match the struct for the `data`.
  For example, a `UserContext` struct should always be passed with
  a `:user` type. No validation will be done by this function,
  however.
  """
  @spec new(Logger.timestamp, context_type, context_data) :: t
  def new(timestamp, type, data) do
    binary_timestamp =
      Timber.Utils.format_timestamp(timestamp)
      |> IO.chardata_to_string()

    %__MODULE__{
      dt: binary_timestamp,
      index: 0,
      type: type,
      data: data
    }
  end

  @spec type_for_data(context_data) :: context_type
  def type_for_data(%Contexts.CustomContext{}), do: :custom
  def type_for_data(%Contexts.ExceptionContext{}), do: :exception
  def type_for_data(%Contexts.HTTPRequestContext{}), do: :http_request
  def type_for_data(%Contexts.HTTPResponseContext{}), do: :http_response
  def type_for_data(%Contexts.OrganizationContext{}), do: :organization
  def type_for_data(%Contexts.SQLQueryContext{}), do: :sql_query
  def type_for_data(%Contexts.ServerContext{}), do: :server
  def type_for_data(%Contexts.TemplateRenderContext{}), do: :template_render
  def type_for_data(%Contexts.UserContext{}), do: :user

  @doc """
  Presents the context the way it should be encoded. The log ingestion system for Timber
  expects contexts to be encoded such that their type is the key holding the context
  specific data.
  """
  def context_for_encoding(context_entry) do
    dt = context_entry.dt
    type = context_entry.type
    index = context_entry.index
    data = context_entry.data

    %{
      :dt => dt,
      :index => index,
      type => data
    }
  end
end
