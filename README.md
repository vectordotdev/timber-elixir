# :evergreen_tree: Timber - Master your Elixir apps with structured logging

<p align="center" style="background: #140f2a;">
<a href="http://github.com/timberio/timber-elixir"><img src="http://files.timber.io/images/ruby-library-readme-header.gif" height="469" /></a>
</p>

[![ISC License](https://img.shields.io/badge/license-ISC-ff69b4.svg)](LICENSE.md) [![Hex.pm](https://img.shields.io/hexpm/v/timber.svg?maxAge=18000=plastic)](https://hex.pm/packages/timber) [![Documentation](https://img.shields.io/badge/hexdocs-latest-blue.svg)](https://hexdocs.pm/timber/index.html) [![CircleCI branch](https://img.shields.io/circleci/project/timberio/timber-elixir/master.svg?maxAge=18000=plastic)](https://circleci.com/gh/timberio/timber-elixir/tree/master)

---

:point_right: **Timber is in beta testing, if interested in joining, please email us at [beta@timber.io](mailto:beta@timber.io)**

---

Timber is a complete, fully-managed, logging strategy that you can set up in minutes. It makes
your application logs useful by taking a different, gentler, smarter approach to structured logging.

To learn more, checkout out [timber.io](https://timber.io) or the
["why we built Timber"](http://moss-ibex2.cloudvent.net/blog/why-were-building-timber/)
blog post.


## Overview

<details><summary><strong>How is Timber different?</strong></summary><p>

1. Timber structures your logs from *within* your application using libraries (like this one);
   a fundamental difference from parsing that has [So. Many. Benefits.](http://moss-ibex2.cloudvent.net/blog/why-were-building-timber/)
2. Timber does not alter the original log message. It structures your logs by *augmenting* them
   with metadata. That is, it preserves the original log message and attaches structured data to
   it. This means you get both: structured data *and* human readable logs.
3. All log events adhere to a [normalized, shared, schema](https://github.com/timberio/log-event-json-schema).
   Meaning you can interact with your logs consistently across apps of any language: queries,
   graphs, alerts, and other downstream consumers. They all operate on the same schema.
4. Timber poses no risk of lock-in or code-debt. There is no special client, no special API; Timber
   adheres strictly to the default `::Logger` interface. On the surface, it's just logging.
   And if you choose to stop using Timber, you can do so without having to alter your code.
5. Timber manages the entire logging pipeline. From log creation (libraries like this one) to a
   [beautiful modern console](https://timber.io) designed specifically for this data.
   The whole process is designed to work in harmony.
6. Lastly, Timber offers 6 months of retention by default, at sane prices. The data is encrypted
   in-transit and at-rest, and we guarantee 11 9s of durability. :open_mouth:

---

</p></details>

<details><summary><strong>What does this Timber library do?</strong></summary><p>

1. Automatically captures and structures your framework and 3rd party logs (see next question).
2. Provides a [framework for logging custom structured events](#what-about-custom-events).
3. Offers transport strategies to [send your logs](#send-your-logs) to the Timber service.

---

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

<details><summary><strong>What about my current log statements?</strong></summary><p>

They'll continue to work as expected. Timber adheres strictly to the default `::Logger` interface
and will never deviate in *any* way.

In fact, traditional log statements for non-meaningful events, debug statements, etc, are
encouraged. In cases where the data is meaningful, consider [logging a custom event](#usage).

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

* `:type` is how Timber classifies the event, it creates a namespace for the data you send.
* For more advanced examples see [`Timber::Logger`](lib/timber.logger.rb).
* Also, notice there is no mention of Timber in the above code. Just plain old logging.

#### What about regular Hashes, JSON, or logfmt?

Go for it! Timber will parse the data server side, but we *highly* recommend the above examples.
Providing a `:type` allows timber to classify the event, create a namespace for the data you
send, and make it easier to search, graph, alert, etc.

```ruby
Logger.info(%{key: "value"})
Logger.info('{"key": "value"}')
Logger.info("key=value")
```

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

:point_right: Prefer examples? Checkout our [Elixir / Phoenix example app](https://github.com/timberio/elixir-phoenix-example-app),
you can see all changes by [searching for "timber-change"](https://github.com/timberio/phoenix-elixir-example-app/search?utf8=%E2%9C%93&q=timber-change&type=Code).

---

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