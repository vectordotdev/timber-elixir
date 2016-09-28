# Timber.io - Powerful Elixir Logging

**Note: Timber is in alpha testing, if interested in joining, please visit http://timber.io

[Timber](http://timber.io) is a different kind of logging platform; it goes beyond traditional
logging by enriching your logs with application level context, turning them into rich, structured
events without altering the essence of logging. See for yourself at [timber.io](http://timber.io).

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `timber` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:timber, "~> 0.1.0"}]
    end
    ```

  2. Ensure `timber` is started before your application:

    ```elixir
    def application do
      [applications: [:timber]]
    end
    ```
