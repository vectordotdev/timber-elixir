defmodule Mix.Tasks.Timber.Install.IOHelper do
  alias Mix.Tasks.Timber.Install.Config

  @nos ["n", "N", "No"]
  @yeses ["y", "Y", "Yes"]

  def ask(prompt) do
    case Config.io_client().gets("#{prompt}: ") do
      value when is_binary(value) ->
        input = String.trim(value)

        if String.length(input) <= 0 do
          puts("Uh oh, we didn't receive an answer :(", :red)
          ask(prompt)
        else
          input
        end

      :eof -> raise("Error getting user input: end of file reached")

      {:error, reason} -> raise("Error gettin guser input: #{inspect(reason)}")
    end
  end

  def ask_yes_no(prompt) do
    case ask(prompt <> " (y/n)") do
      v when v in @yeses -> :yes
      v when v in @nos -> :no

      v ->
        puts("#{inspect(v)} is not a valid option. Please try again.\n", :red)
        ask_yes_no(prompt)
    end
  end

  def puts(message), do: Config.io_client().puts(message)

  def puts(message, color) do
    IO.ANSI.format([color, message])
    |> Config.io_client().puts()
  end

  def write(message) do
    Config.io_client().write(message)
  end

  def write(message, color) do
    IO.ANSI.format([color, message])
    |> Config.io_client().write()
  end
end