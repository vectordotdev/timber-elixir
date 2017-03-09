defmodule Mix.Tasks.Timber.Install.Event do
  alias Mix.Tasks.Timber.Install.Config

  def send!(name, session_id, api_key, opts \\ []) do
    data = Keyword.get(opts, :data)
    Config.http_client().request!(session_id, :post, "/installer/events", api_key: api_key,
      body: %{event: %{name: name, data: data}})
  end
end