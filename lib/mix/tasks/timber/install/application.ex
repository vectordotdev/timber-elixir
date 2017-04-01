defmodule Mix.Tasks.Timber.Install.Application do
  @moduledoc false

  alias __MODULE__.MalformedApplicationPayload
  alias Mix.Tasks.Timber.Install.API

  defstruct [
    :api_key,
    :heroku_drain_url,
    :name,
    :platform_type,
    :slug
  ]

  def new!(api) do
    response = API.application!(api)

    case response do
      {200, %{"api_key" => api_key, "heroku_drain_url" => heroku_drain_url, "name" => name,
        "platform_type" => platform_type, "slug" => slug}}
      ->

        %__MODULE__{
          api_key: api_key,
          heroku_drain_url: heroku_drain_url,
          name: name,
          platform_type: platform_type,
          slug: slug
        }

      {200, payload} -> raise(MalformedApplicationPayload, payload: payload)
    end
  end

  #
  # Errors
  #

  defmodule MalformedApplicationPayload do
    defexception [:message]

    def exception(opts) do
      payload = Keyword.fetch!(opts, :payload)
      message =
        """
        Uh oh! We received a malformed application payload:

        #{inspect(payload)}
        """
      %__MODULE__{message: message}
    end
  end
end
