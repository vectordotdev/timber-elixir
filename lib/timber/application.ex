defmodule Timber.Application do
  @moduledoc false

  use Application

  @doc false
  # Handles the application callback start/2
  #
  # Starts an empty supervisor in order to comply with callback expectations
  #
  # This is the function that starts up the error logger listener
  #
  def start(_type, _opts) do
    import Supervisor.Spec, warn: false

    Timber.Cache.init()

    children = []

    opts = [strategy: :one_for_one, name: Timber.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
