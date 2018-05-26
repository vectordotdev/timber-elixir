defmodule Timber.Integrations.ContextPlug do
  @moduledoc """
  Deprecated

  This module is deprecated as of version 2.3.0 and will be removed
  in version 3.0 and beyond. Use `Timber.Integrations.HTTPContextPlug`
  and `Timber.Integrations.SessionContextPlug` instead.

  Until this module is removed, it will mimic previous functionality by
  calling `Timber.Integrations.HTTPContextPlug` followed by
  `Timber.Integrations.SessionContextPlug`.
  """

  @doc """
  Deprecated
  """
  @spec init(Plug.opts()) :: Plug.opts()
  def init(opts) do
    opts
    |> Timber.Integrations.SessionContextPlug.init()
    |> Timber.Integrations.HTTPContextPlug.init()
  end

  @doc """
  Deprecated
  """
  @spec call(Plug.Conn.t(), Plug.opts()) :: Plug.Conn.t()
  def call(conn, opts) do
    conn
    |> Timber.Integrations.SessionContextPlug.call(opts)
    |> Timber.Integrations.HTTPContextPlug.call(opts)
  end
end
