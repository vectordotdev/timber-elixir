# :evergreen_tree: Timber - Master your Elixir apps with structured logging

<p align="center" style="background: #140f2a;">
<a href="http://github.com/timberio/timber-elixir"><img src="http://files.timber.io/images/ruby-library-readme-header.gif" height="469" /></a>
</p>

[![ISC License](https://img.shields.io/badge/license-ISC-ff69b4.svg)](LICENSE) [![Hex.pm](https://img.shields.io/hexpm/v/timber.svg?maxAge=18000=plastic)](https://hex.pm/packages/timber) [![Documentation](https://img.shields.io/badge/hexdocs-latest-blue.svg)](https://hexdocs.pm/timber/index.html) [![CircleCI branch](https://img.shields.io/circleci/project/timberio/timber-elixir/master.svg?maxAge=18000=plastic)](https://circleci.com/gh/timberio/timber-elixir/tree/master) [![Coverage Status](https://coveralls.io/repos/github/timberio/timber-elixir/badge.svg?branch=master)](https://coveralls.io/github/timberio/timber-elixir=master)

**Note: Timber is in alpha testing, if interested in joining, please visit https://timber.io**

Logs are great...when they're structured. And unless your a logging company, designing and
implementing a structured logging strategy can be a time sink. Not only do you have to deal
with 3rd party libraries, but you need to agree on a schema and a standard your team will follow.

Timber gives you all of this today. *And*, we've built a beautiful modern console designed
specifically for this data. *And*, we give you *6 months* of retention at a price cheaper than
any alternative. *And*, we don't charge you extra for the structured data we're encouraging here.
*And* your data is encrypted with 11 9s of durability. And...so many things!

Timber's goal is to remove *any* barrier that gets in the way of realizing the power of structured
logging.

To learn more, checkout out [timber.io](https://timber.io) or the ["why we started Timber"](http://moss-ibex2.cloudvent.net/blog/why-were-building-timber/)
blog post.


## What events does Timber structure for me?

Out of the box you get everything in the `Timber.Events` namespace:

1. [Controller Calls]()
2. [Exceptions]()
3. [Outgoing HTTP requests]()
4. [Outgoing HTTP responses]()
5. [Incoming HTTP requests]()
6. [Incoming HTTP responses]()
7. [SQL Queries]()
8. [Template Renders]()
9. ...more coming! [Make an issue](https://github.com/timberio/timber-elixir/issues) if you'd like
   to request support for other types.


## What about custom events?

No probs! We've put careful thought in how this would be implemented. You have a couple of options
depending on how strict you want to be with structuring your data.

1. Log a map (simplest)

  ```elixir
  event_data = %{customer_id: "xiaus1934", amount: 1900, currency: "USD"}
  Logger.info("Payment rejected", event: %{type: :payment_rejected, data: event_data})
  ```

2. Log a struct (recommended)

  Defining structs for your important events just feels oh so good :) It creates a strong contract
  with down stream consumers and gives you compile time guarantees. It makes a statement that
  this event means something and that it can relied upon.

  ```elixir
  def PaymentRejectedEvent do
    use Timber.Events.CustomEvent, type: :payment_rejected

    @enforce_keys [:customer_id, :amount, :currency]
    defstruct [:customer_id, :amount, :currency]

    def message(%__MODULE__{customer_id: customer_id}) do
      "Payment rejected for #{customer_id}"
    end
  end

  event = %PaymentRejectedEvent{customer_id: "xiaus1934", amount: 1900, currency: "USD"}
  message = PaymentRejectedEvent.message(event)
  Logger.info(message, event: event)
  ```

Notice there are no special APIs, no risk of code-debt, and no lock-in. Just better logging.


## Installation

1. Add Timber as a dependency:

  ```elixir
  # Mix.exs

  def application do
    [applications: [:timber]]
  end

  def deps do
    [{:timber, "~> 0.4"}]
  end
  ```

2. Configure Timber:

  ```elixir
  # config/config.exs

  config :logger,
    backends: [Timber.LoggerBackend],
    handle_otp_reports: false # Timber handles this and adds additional metadata

  config :timber, :capture_errors, true
  ```

3. Add the Timber plugs:

  Skip if you are not using `Plug`.

  ```elixir
  # web/router.ex

  defmodule MyApp.Router do
    use MyApp.Web, :router

    pipeline :logging do
      plug Timber.Integrations.ContextPlug
      plug Timber.Integrations.EventPlug
    end

    scope "/api", MyApp do
      pipe_through :logging
    end
  end
  ```

  * To learn more about what each of these plugs are doing, checkout the docs:
    [Timber.Integrations.ContextPlug](lib/timber/integrations/context_plug.ex) and
    [Timber.Integrations.EventPlug](lib/timber/integrations/event_plug.ex)

4. Add Phoenix instrumentation:

  Skip if you are not using `Phoenix`.

  ```elixir
  # config/config.exs

  config :my_app, MyApp.Endpoint,
    http: [port: 4001],
    root: Path.dirname(__DIR__),
    instrumenters: [Timber.Integrations.PhoenixInstrumenter], # <------
    pubsub: [name: MyApp.PubSub,
             adapter: Pheonix.PubSub.PG2]
  ```

5. Add the Ecto logger:

  Skip if you are not using `Ecto`.

  ```elixir
  # config/config.exs

  config :my_app, MyApp.Repo,
    loggers: [{Timber.Integrations.EctoLogger, :log, [:info]}] # Bump to info to gain more insight
  ```


## Transport Installation

We *highly* recommend that you obtain these transport instructions from within
[the Timber app](https://app.timber.io). During the app creation process we collect details
about your app, and at the end, we provide you with simple, copy-paste, instructions for your
exact environment (API key included).


### STDOUT

Do nothing! This is the default transport strategy.

### File

1. Configure the Timber transport strategy:

  ```elixir
  config :timber, :transport, Timber.Transports.IODevice
  config :timber, :io_device,
    file: "path/to/file",
  ```

### HTTP

Coming soon!


## Development environment

Bonus points! Use Timber in your development environment so you can see context locally:

```elixir
# config/dev.exs

config :timber, :io_device,
  colorize: true,
  format: :logfmt,
  print_timestamps: true
  print_log_level: true
```