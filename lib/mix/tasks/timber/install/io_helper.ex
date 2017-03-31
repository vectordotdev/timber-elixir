defmodule Mix.Tasks.Timber.Install.IOHelper do
  @moduledoc false

  alias Mix.Tasks.Timber.Install.{API, Config}

  @nos ["n", "N", "No"]
  @yeses ["y", "Y", "Yes"]

  def ask(prompt, api) do
    API.event!(api, :waiting_for_input, %{prompt: prompt})

    case Config.io_client().gets("#{prompt}: ") do
      value when is_binary(value) ->
        input = String.trim(value)

        if String.length(input) <= 0 do
          puts("Uh oh, we didn't receive an answer :(", :red)
          ask(prompt, api)
        else
          API.event!(api, :received_input, %{prompt: prompt, value: input})

          input
        end

      :eof -> raise("Error getting user input: end of file reached")

      {:error, reason} -> raise("Error gettin guser input: #{inspect(reason)}")
    end
  end

  def ask_yes_no(prompt, api) do
    case ask(prompt <> " (y/n)", api) do
      v when v in @yeses -> :yes
      v when v in @nos -> :no

      v ->
        puts("#{inspect(v)} is not a valid option. Please try again.\n", :red)
        ask_yes_no(prompt, api)
    end
  end

  def colorize(message, color) do
    IO.ANSI.format([color, message])
  end

  def puts(message), do: Config.io_client().puts(message)

  def puts(message, color) do
    colorize(message, color)
    |> Config.io_client().puts()
  end

  def write(message) do
    Config.io_client().write(message)
  end

  def write(message, color) do
    colorize(message, color)
    |> Config.io_client().write()
  end
end