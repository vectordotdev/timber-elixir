defmodule Timber.Integrations do
  def ecto? do
    Code.ensure_loaded?(Ecto)
  end

  def phoenix? do
    Code.ensure_loaded?(Phoenix)
  end

  def plug? do
    Code.ensure_loaded?(Plug)
  end
end