defmodule Timber.CurrentContext do
  @moduledoc """
  Deprecated in favor of `Timber.LocalContext`

  This module has been deprecated and is scheduled for removal in
  v3.0.0.
  """

  defdelegate load(), to: Timber.LocalContext
  defdelegate extract_from_metadata(metadata), to: Timber.LocalContext
  defdelegate save(context), to: Timber.LocalContext
end
