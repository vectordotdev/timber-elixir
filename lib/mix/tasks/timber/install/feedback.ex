defmodule Mix.Tasks.Timber.Install.Feedback do
  alias Mix.Tasks.Timber.Install.IOHelper

  def collect do
    case IOHelper.ask("How would rate this install experience? 1 (bad) - 5 (perfect)") do
      v when v in ["4", "5"] ->
        IOHelper.puts("💖 We love you too! Let's get to loggin' 🌲")

      v when v in ["1", "2", "3"] ->
        IOHelper.puts("Bummer! That is certainly not the experience we were going for.")

        case IOHelper.ask_yes_no("May we email you to resolve the issue you're having? (y/n)") do
          :yes ->
            IOHelper.puts("Great! We'll be in touch.")

          :no ->
            IOHelper.puts("Thank you trying Timber anyway. We wish we would have left a better impression.")
        end

      v ->
        IOHelper.puts("#{inspect(v)} is not a valid option. Please try again.\n", :red)
        collect()
    end

    :ok
  end
end