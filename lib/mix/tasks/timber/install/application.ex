defmodule Mix.Tasks.Timber.Install.Application do
  @moduledoc false

  alias __MODULE__.MalformedApplicationPayload
  alias Mix.Tasks.Timber.Install.{API, IOHelper}

  defstruct [
    :api_key,
    :heroku_drain_url,
    :mix_name,
    :module_name,
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
        mix_name = get_mix_name(api)
        module_name = Macro.camelize(mix_name)

        %__MODULE__{
          api_key: api_key,
          heroku_drain_url: heroku_drain_url,
          mix_name: mix_name,
          module_name: module_name,
          name: name,
          platform_type: platform_type,
          slug: slug
        }

      {200, payload} -> raise(MalformedApplicationPayload, payload: payload)
    end
  end

  #
  # Utility
  #

  defp get_mix_name(api) do
    case File.cwd() do
      {:ok, cwd} ->
        cwd
        |> Path.split()
        |> List.last()
        |> String.replace("-", "_")

      {:error, _reason} ->
        IOHelper.ask("What's the name of your application? (please use snake_case, ex: my_app)", api)
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
