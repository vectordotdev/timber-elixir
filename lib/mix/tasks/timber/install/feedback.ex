defmodule Mix.Tasks.Timber.Install.Feedback do
  alias Mix.Tasks.Timber.Install.{Config, IOHelper}

  def collect(api_key) do
    case IOHelper.ask("How would rate this install experience? 1 (bad) - 5 (perfect)") do
      v when v in ["4", "5"] ->
        send!(api_key, %{rating: v})

        """

        💖  We love you too! Let's get to loggin' 🌲
        """
        |> IOHelper.puts()

      v when v in ["1", "2", "3"] ->
        """

        Bummer! That is certainly not the experience we were going for.

        Could you tell us why you a bad experience?

        (this will be sent directly to the Timber engineering team)
        """
        |> IOHelper.puts()

        case IOHelper.ask("Type your comments (enter sends)") do
          comments ->
            send!(api_key, %{rating: v, comments: comments})

            """

            Thank you! We take feedback seriously and will work to resolve this.
            """
            |> IOHelper.puts()
        end

      v ->
        IOHelper.puts("#{inspect(v)} is not a valid option. Please enter a number between 1 and 5.\n", :red)
        collect(api_key)
    end

    :ok
  end

  defp send!(api_key, body) do
    Config.http_client().request!(:post, "/installer/feedback", api_key: api_key, body: %{feedback: body})
  end
end