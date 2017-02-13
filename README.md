# :evergreen_tree: Timber - Master your Elixir apps with structured logging

<p align="center" style="background: #140f2a;">
<a href="http://github.com/timberio/timber-elixir"><img src="http://files.timber.io/images/ruby-library-readme-header.gif" height="469" /></a>
</p>

[![ISC License](https://img.shields.io/badge/license-ISC-ff69b4.svg)](LICENSE.md) [![Hex.pm](https://img.shields.io/hexpm/v/timber.svg?maxAge=18000=plastic)](https://hex.pm/packages/timber) [![Documentation](https://img.shields.io/badge/hexdocs-latest-blue.svg)](https://hexdocs.pm/timber/index.html) [![CircleCI branch](https://img.shields.io/circleci/project/timberio/timber-elixir/master.svg?maxAge=18000=plastic)](https://circleci.com/gh/timberio/timber-elixir/tree/master)

---

:point_right: **Timber is in beta testing, if interested in joining, please email us at [beta@timber.io](mailto:beta@timber.io)**

---

Timber is a complete, high-quality, carefully designed logging solution that you can setup
in minutes. It goes beyond traditional log management by focusing on data quality and modern
user experiences.

High quality logs, a modern beautiful interface, simple setup, zero-maintenance, 6-month retention,
and sane prices are just a few of the differences Timber offers.

To learn more, checkout out [timber.io](https://timber.io) or the
["why we built Timber"](http://moss-ibex2.cloudvent.net/blog/why-were-building-timber/)
blog post.


## Overview

<details><summary><strong>How does Timber benefit me differently?</strong></summary><p>

1. **Data quality.** The usefulness of your logs starts here. This is why we ship libraries like
   this one; a fundamental difference from parsing. Timber maintains the entire process of
   structuring your logs from *within* your application: from framework logs, to 3rd party logs,
   to custom events. Moreover, Timber adds data that otherwise wouldn't be in the line; data you
   can't obtain from parsing alone.
2. **Human readability.** Structuring your logs means they become unreadable. Timber
   *augments* your logs with structured data. Meaning we do not alter the original log message.
   And in the Timber console, you'll see the humany-friendly message. Click the line, and you'll
   get access to all of the structured data in a slide out panel. :open_mouth:
3. **Reliable downstream consumption.** All log events adhere to a
   [normalized, shared, schema](https://github.com/timberio/log-event-json-schema) that follows
   [semantic versioning](http://semver.org/) and goes through a [standard release process](https://github.com/timberio/log-event-json-schema/releases).
   This means you can rely on the structure of your logs and interact consistently with them
   across apps of any language: queries, graphs, alerts, and other downstream consumers. No
   surprises, less breakage, more reliability, happier developers. :smile:
4. **Zero risk of code debt or lock-in.** Logging is a standard that has been around since the dawn
   of computers. It's built into every language, framework, and library. Timber adheres strictly
   to the default `Logger` interface. There are no special APIs, and no need to pepper your app
   with Timber specific code. It's just better logging. If you choose to stop using Timber, you
   can do so without consequence.
5. **Long term retention.** Timber is designed on modern big-data principles. As a result, we can
   offer 6+ months of retention at prices cheaper than alternatives offering <1 month.
   This allows you to unlock your logs for purposes beyond debugging.

---

</p></details>

<details><summary><strong>What specifically does the Timber library do?</strong></summary><p>

1. Automatically captures and structures your framework and 3rd party logs. (see next question)
2. Adds useful context to every log line. (see next question)
3. Provides a [framework for logging custom structured events](#what-about-custom-events).
4. Offers transport strategies to [send your logs](#send-your-logs) to the Timber service.

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

---

</p></details>

<details><summary><strong>What about my current log statements?</strong></summary><p>

They'll continue to work as expected. Timber adheres strictly to the default `Logger` interface
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

---

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

---

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

:point_right: Prefer examples? Checkout out the **[Timber install example pull requst](https://github.com/timberio/elixir-phoenix-example-app/pull/1/files)**.
This demonstrates the below changes for a default Phoenix application.

---

<details><summary><strong>1. *Configure* Timber in `config/config.exs`</strong></summary><p>

Replace *any* existing `config :logger` calls with:

```elixir
# config/config.exs

config :logger,
  backends: [Timber.LoggerBackend],
  handle_otp_reports: false # Timber handles errors, structures them, and adds additional metadata

config :timber, :capture_errors, true
```

</p></details>

<details><summary><strong>2. *Capture* `Plug` logging in `lib/my_app/endpoint.ex`</strong></summary><p>

:point_right: *Skip if you are not using `Plug`.*

```elixir
# lib/my_app/endpoint.ex

plug Plug.Logger # <--- REMOVE THIS LINE

...

# ADD THESE LINES
# Insert at the bottom, immediately before `plug MyApp.Router`
plug Timber.Integrations.ContextPlug
plug Timber.Integrations.EventPlug

plug MyApp.Router
```

* Be sure to insert these plugs at the bottom of your `endpoint.ex` file, *immediately* before
  `plug MyApp.Router`. This ensures Timber captures the request ID and other useful context.

</p></details>

<details><summary><strong>3. *Capture* `Phoenix` logging in `config/config.exs` and `my_app/web.ex`</strong></summary><p>

:point_right: *Skip if you are not using `Phoenix`.*

```elixir
# config/config.exs

config :my_app, MyApp.Endpoint,
  instrumenters: [Timber.Integrations.PhoenixInstrumenter]
```

Now that Timber is handling logging, disable Phoenix logging with:

```elixir
# my_app/web.ex

def controller do
  quote do
    use Phoenix.Controller, log: false # <--- Add log: false
  end
end
```

</p></details>

<details><summary><strong>4. *Capture* `Ecto` logging in `config/config.exs`</strong></summary><p>

:point_right: *Skip if you are not using `Ecto`.*

```elixir
# config/config.exs

config :my_app, MyApp.Repo,
  loggers: [{Timber.Integrations.EctoLogger, :log, [:info]}]
```

</p></details>

<details><summary><strong>5. *Configure* Timber for development in `config/dev.exs`</strong></summary><p>

Now that Timber is all set up, we want to make sure it's development friendly:

```elixir
# config/dev.exs

config :timber, :io_device,
  colorize: true,
  format: :logfmt,
  print_timestamps: true,
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

4. Assign your API key to the `TIMBER_LOGS_KEY` environment variable.

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