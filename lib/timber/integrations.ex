defmodule Timber.Integrations do
  @moduledoc false

  def ecto? do
    Code.ensure_loaded?(Ecto)
  end

  def phoenix? do
    Code.ensure_loaded?(Phoenix)
  end
end