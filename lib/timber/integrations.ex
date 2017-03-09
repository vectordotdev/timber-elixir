defmodule Timber.Integrations do
  def ecto? do
    Code.ensure_loaded?(Ecto)
  end

  def phoenix? do
    Code.ensure_loaded?(Phoenix)
  end
end