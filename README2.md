# Timber - Master your Elixir apps with structured logging :evergreen_tree:

<p align="center" style="background: #140f2a;">
<a href="http://github.com/timberio/timber-ruby"><img src="http://res.cloudinary.com/timber/image/upload/c_scale,w_537/v1464797600/how-it-works_sfgfjp.gif" /></a>
</p>

[![ISC License](https://img.shields.io/badge/license-ISC-ff69b4.svg)](LICENSE) [![Hex.pm](https://img.shields.io/hexpm/v/timber.svg?maxAge=18000=plastic)](https://hex.pm/packages/timber) [![Documentation](https://img.shields.io/badge/hexdocs-latest-blue.svg)](https://hexdocs.pm/timber/index.html) [![CircleCI branch](https://img.shields.io/circleci/project/timberio/timber-elixir/master.svg?maxAge=18000=plastic)](https://circleci.com/gh/timberio/timber-elixir/tree/master) [![Coverage Status](https://coveralls.io/repos/github/timberio/timber-elixir/badge.svg?branch=master)](https://coveralls.io/github/timberio/timber-elixir=master)

**Note: Timber is in alpha testing, if interested in joining, please visit https://timber.io**

Logs are great...when they're structured. And unless your a logging company, designing and
implementing a structured logging strategy can be a time sink. Not only do you have to deal
with 3rd party libraries, but you need to agree on a schema, and a standard your team will follow.

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
9. More coming! [Make an issue]() if you'd like to request support for other types.

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
def MyApp.Events.PaymentRejected do
  @enforce_keys [:customer_id, :amount, :currency]
  defstruct [:customer_id, :amount, :currency]
  def type, do: :payment_rejected
end

event = %MyApp.Events.PaymentRejected{customer_id: "xiaus1934", amount: 1900, currency: "USD"}
Logger.info("Payment rejected", event: event)
```


## Library Installation

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

2. Add Timber as a Logger backend:

  ```elixir
  # usually config/config.exs
  config :logger, backends: [Timber.Logger]
  ```

3. Add the Timber plugs:

  Skip if you are not using `Plug`.

  ```elixir
  defmodule MyApp.Router do
    use MyApp.Web, :router

    pipeline :logging do
      plug Timber.ContextPlug
      plug Timber.EventPlug
    end

    scope "/api", MyApp do
      pipe_through :logging
    end
  end
  ```

  * To learn more about what each of these plugs are doing, checkout the docs: [Timber.ContextPlug]() and [Timber.EventPlug]()

4. Add Phoenix instrumentation:

  Skip if you are not using `Phoenix`.

  ```elixir
  config :my_app, MyApp.Endpoint,
    http: [port: 4001],
    root: Path.dirname(__DIR__),
    instrumenters: [Timber.PhoenixInstrumenter], # <------
    pubsub: [name: MyApp.PubSub,
             adapter: Pheonix.PubSub.PG2]
  ```

5. Add the Ecto logger:

  Skip if you are not using `Ecto`.

  ```elixir
  config :my_app, MyApp.Repo,
    loggers: [{Timber.Ecto, :log, [:info]}] # Feel free to adjust the level
  ```

## Transport Installation

We *highly* recommend that you [create an application in your Timber account](https://app.timber.io).
Based on the details provided, we'll recommend simple instructions specific to your environment.


### IO (STDOUT)

1. Configure the Timber transport strategy:

  ```elixir
  config :timber, :transport, Timber.Transports.IODevice
  ```

2. Bonus points: Make your development logs nicer:

  ```
  # config/dev.exs

  config :timber, :io_device,
    colorize: true,
    format: :logfmt,
    print_timestamps: true
    print_log_level: true
  ```

## HTTP

Coming soon!