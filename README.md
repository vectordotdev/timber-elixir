# :evergreen_tree: Timber - Master your Elixir apps with structured logging

<p align="center" style="background: #140f2a;">
<a href="http://github.com/timberio/timber-elixir"><img src="http://files.timber.io/images/ruby-library-readme-header.gif" height="469" /></a>
</p>

[![ISC License](https://img.shields.io/badge/license-ISC-ff69b4.svg)](LICENSE.md) [![Hex.pm](https://img.shields.io/hexpm/v/timber.svg?maxAge=18000=plastic)](https://hex.pm/packages/timber) [![Documentation](https://img.shields.io/badge/hexdocs-latest-blue.svg)](https://hexdocs.pm/timber/index.html) [![CircleCI branch](https://img.shields.io/circleci/project/timberio/timber-elixir/master.svg?maxAge=18000=plastic)](https://circleci.com/gh/timberio/timber-elixir/tree/master)

---

:point_right: **Timber is in beta testing, if interested in joining, please email us at [beta@timber.io](mailto:beta@timber.io)**

---

Timber is a complete, fully-managed, *structured* logging system that you can setup in
minutes. It pairs libraries that automatically structure your logs (like this one),
with a [beautiful modern console](https://timber.io) designed specifically for this data.

To learn more, checkout out [timber.io](https://timber.io) or the
["why we built Timber"](http://moss-ibex2.cloudvent.net/blog/why-were-building-timber/)
blog post.


## Overview

<details><summary><strong>What does Timber do?</strong></summary><p>

To extend the above description, Timber...

1. Automatically structures your framework and 3rd party logs (see next question).
2. Provides a [framework for logging custom events](#what-about-custom-events).
3. Does not lock you in with a special API or closed data. Just better logging.
4. Defines a [normalized log schema](https://github.com/timberio/log-event-json-schema) across *all* of your apps. Implemented by [our libraries](https://github.com/timberio).
5. Offers a [beautiful modern console](https://timber.io) designed specifically for this data. Pre-configured and tuned out of the box.
6. Gives you *6 months of retention*, by default.
7. Does not charge you for the extra structured data we're encouraging here, only the core log message.
8. Encrypts your data in transit and at rest.
9. Offers 11 9s of durability.
10. ...and so much more!

</p></details>

<details><summary><strong>What events does Timber capture & structure for me?</strong></summary><p>

Out of the box you get everything in the [`Timber.Events`](lib/timber/events) namespace:

1. [Controller Call Event](lib/timber/events/controller_call_event.ex)
2. [Exception Event](lib/timber/events/exception_event.ex)
3. [HTTP Client Request Event (outgoing)](lib/timber/events/http_client_request_event.ex)
4. [HTTP Client Response Event](lib/timber/events/http_client_response_event.ex)
5. [HTTP Server Request Event (incoming)](lib/timber/events/http_server_request_event.ex)
6. [HTTP Server Response Event](lib/timber/events/http_server_response_event.ex)
7. [SQL Query Event](lib/timber/events/sql_query_event.ex)
8. [Template Render Event](lib/timber/events/template_render_event.ex)
9. ...more coming soon, [file an issue](https://github.com/timberio/timber-elixir/issues) to request.

We also add context to every log, everything in the [`Timber.Contexts`](lib/timber/contexts)
namespace. Context is structured data representing the current environment when the log line was written.
It is included in every log line. Think of it like join data for your logs:

1. [HTTP Context](lib/timber/contexts/http_context.ex)
2. [Organization Context](lib/timber/contexts/organization_context.ex)
3. [Server Context](lib/timber/contexts/server_context.ex)
4. [System Context](lib/timber/contexts/system_context.ex)
5. [Runtime Context](lib/timber/contexts/runtime_context.ex)
5. [User Context](lib/timber/contexts/user_context.ex)
6. ...more coming soon, [file an issue](https://github.com/timberio/timber-elixir/issues) to request.

</p></details>


## Usage

<details><summary><strong>Basic logging</strong></summary><p>

No client, no special API, no magic, just use `Logger` as normal:

```elixir
Logger.info("My log message")
```

</p></details>

<details><summary><strong>Custom events</strong></summary><p>

1. Log a map (simplest)

  The simplest way to send an event and kick the tires:

  ```elixir
  event_data = %{customer_id: "xiaus1934", amount: 1900, currency: "USD"}
  Logger.info("Payment rejected", event: %{type: :payment_rejected, data: event_data})
  ```

2. Log a struct (recommended)

  Defining structs for your important events just feels oh so good :) It creates a strong contract
  with down stream consumers and gives you compile time guarantees.

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

* Notice there are no special APIs, no risk of code-debt, and no lock-in. Just better logging.

</p></details>

<details><summary><strong>Custom contexts</strong></summary><p>

Context is additional data shared across log lines. Think of it like join data. For example, the
`http.request_id` is included in the context, allowing you to view all log lines related to that
request ID. Not just the lines that contain the value.

1. Add a map (simplest)

  The simplest way to add context is:

  ```elixir
  Timber.add_context(%{type: :build, data: %{version: "1.0.0"}})
  ```

  This adds context data keyspaces by `build`.

2. Add a struct (recommended)

  Just like events, we recommend defining your custom contexts. It makes a stronger contract
  with downstream consumers.

  ```elixir
  def BuildContext do
    use Timber.Contexts.CustomContext, type: :build
    @enforce_keys [:version]
    defstruct [:version]
  end

  Timber.add_context(%BuildContext{version: "1.0.0"})
  ```

</p></details>


## Installation

```elixir
# Mix.exs

def application do
  [applications: [:timber]]
end

def deps do
  [{:timber, "~> 1.0"}]
end
```


## Setup

<details><summary><strong>1. *Configure* Timber in `config/config.exs`</strong></summary><p>

  ```elixir
  # config/config.exs

  config :logger,
    backends: [Timber.LoggerBackend],
    handle_otp_reports: false # Timber handles errors, structures them, and adds additional metadata

  config :timber, :capture_errors, true
  ```

</p></details>

<details><summary><strong>2. *Add* the Timber plugs in `lib/my_app/endpoint.ex`</strong></summary><p>

  :point_right: *Skip if you are not using `Plug`.*

  ```elixir
  # lib/my_app/endpoint.ex

  plug Plug.Logger # <--- REMOVE ME

  ...

  # Insert immediately before plug MyApp.Router
  plug Timber.Integrations.ContextPlug
  plug Timber.Integrations.EventPlug

  plug MyApp.Router
  ```

  * Be sure to insert these plugs at the bottom of your `endpoint.ex` file, immediately before
    `plug MyApp.Router`. This ensures Timber captures the request ID and other useful context.

</p></details>

<details><summary><strong>3. *Add* Phoenix instrumentation in `config/config.exs`</strong></summary><p>

  :point_right: *Skip if you are not using `Phoenix`.*

  ```elixir
  # config/config.exs

  config :my_app, MyApp.Endpoint,
    http: [port: 4001],
    root: Path.dirname(__DIR__),
    instrumenters: [Timber.Integrations.PhoenixInstrumenter], # <------ add this line
    pubsub: [name: MyApp.PubSub,
             adapter: Pheonix.PubSub.PG2]
  ```

</p></details>

<details><summary><strong>4. *Add* the Ecto logger in `config/config.exs`</strong></summary><p>

  :point_right: *Skip if you are not using `Ecto`.*

  ```elixir
  # config/config.exs

  config :my_app, MyApp.Repo,
    loggers: [{Timber.Integrations.EctoLogger, :log, [:info]}] # Bumped to info to gain more insight
  ```

</p></details>

<details><summary><strong>5. (optional) *Configure* Timber for development in `config/dev.exs`</strong></summary><p>

  Bonus points! Use Timber in your development environment so you can see context locally:

  ```elixir
  # config/dev.exs

  config :timber, :io_device,
    colorize: true,
    format: :logfmt,
    print_timestamps: true
    print_log_level: true
  ```

</p></details>


## Send your logs

<details><summary><strong>Heroku (log drains)</strong></summary><p>

The recommended strategy for Heroku is to setup a
[log drain](https://devcenter.heroku.com/articles/log-drains). To get your Timber log drain URL:

**--> [Add your app to Timber](https://app.timber.io)**

*:information_desk_person: Note: for high volume apps Heroku log drains will drop messages. This
is true for any Heroku app, in which case we recommend the Network method below.*

---

</p></details>

<details><summary><strong>All other platforms (Network / HTTP)</strong></summary><p>

Timber does *not* force an HTTP client on you. The following instruction utilize the Timber default
`Timber.Transports.HTTP.HackneyClient`. This is a highly efficient client that utilizes hackney,
batching, stay alive connections, connection pools, and msgpack to deliver logs with high
throughput and little overhead. If you'd like to use another client see
`Timber.Transports.HTTP.Client`.

1. *Add* HTTP dependencies to `mix.exs`:

  ```elixir
  # Elixir >= 1.4? Adding the applications list is optional.
  def application do
    [applications: [:hackney, :timber]] # <-- Be sure to add hackney!
  end

  def deps do
    [
      {:timber, "~> 1.0"},
      {:hackney, "~> 1.6"} # <-- ADD ME
    ]
  end
  ```

2. *Configure* Timber to use the Network transport in `config/prod.exs`:

  ```elixir
  # config/prod.exs

  config :timber,
    transport: Timber.Transports.Network,
    api_key: System.get_env("TIMBER_LOGS_KEY")
  ```

3. Obtain your Timber API :key: by **[adding your app in Timber](https://app.timber.io)**.
   Afterwards simply assign it to the `TIMBER_LOGS_KEY` environment variable.

* Note: we use the `Network` transport so that we can upgrade protocols in the future if we
  deem it more efficient. For example, TCP. If you want to use strictly HTTP, simply replace
  `Timber.Transports.Network` with `Timber.Transports.HTTP`.

---

</p></details>

<details><summary><strong>Advanced setup (syslog, file tailing agent, etc)</strong></summary><p>

Checkout our [docs](https://timber.io/docs) for a comprehensive list of install instructions.

</p></details>


---

<p align="center" style="background: #140f2a;">
<a href="http://github.com/timberio/timber-elixir"><img src="http://files.timber.io/images/ruby-library-readme-log-truth.png" height="947" /></a>
</p>