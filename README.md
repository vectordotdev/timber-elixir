# 🌲 Timber - Master your Elixir apps with structured logging

<p align="center" style="background: #140f2a;">
<a href="http://files.timber.io/images/readme-interface.gif"><img src="http://files.timber.io/images/readme-interface.gif" width="100%" /></a>
</p>

[![ISC License](https://img.shields.io/badge/license-ISC-ff69b4.svg)](LICENSE.md) [![Hex.pm](https://img.shields.io/hexpm/v/timber.svg?maxAge=18000=plastic)](https://hex.pm/packages/timber) [![Documentation](https://img.shields.io/badge/hexdocs-latest-blue.svg)](https://hexdocs.pm/timber/index.html) [![CircleCI branch](https://img.shields.io/circleci/project/timberio/timber-elixir/master.svg?maxAge=18000=plastic)](https://circleci.com/gh/timberio/timber-elixir/tree/master)

Timber solves logging so you don't have to. It's a _structured_ logging system that you can
setup in minutes; automatically turning your logs into rich structured events.

* [Timber website](https://timber.io)
* [Library documentation](https://hex.pm/packages/timber)
* [Support](mailto:support@timber.io)

## Overview

Timber for Elixir pairs with the [Timber console](https://app.timber.io) to provide a complete
structured logging system. There are no special APIs or agents; it works directly with the standard
`Logger`. It's better, structured logging without the massive time investment.

It turns this:

```
Sent 200 in 45.ms
```

Into this:

```
Sent 200 in 45.2ms @metadata {"dt": "2017-02-02T01:33:21.154345Z", "level": "info", "context": {"user": {"id": 1}}, "event": {"http_response": {"status": 200, "time_ms": 45.2}}}
```

Allowing you to run queries like:

1. `context.request_id:abcd1234` - View all logs generated for a specific request
2. `context.user.id:1` - View logs generated by a specific user.
3. `type:exception` - View all exceptions with the ability to zoom out and view them in context (request, user, etc).
4. `http_server_response.status:500` - View all 500 responses with the ability to zoom out and view them in context (request, user, etc).


## Installation

1. Add `timber` as a dependency in `mix.exs`:

    ```elixir
    # Mix.exs

    def application do
      [applications: [:timber]]
    end

    def deps do
      [{:timber, "~> 1.0"}]
    end
    ```

2. Run `mix deps.get` in your shell.

3. Run `mix timber.install your-timber-application-api-key`

    * You can obtain your API key by [adding your application within Timber](https://app.timber.io)


## Usage

<details><summary><strong>Basic logging</strong></summary><p>

No special API, Timber works directly with `Logger`:

```elixir
Logger.info("My log message")

# My log message @metadata {"level": "info", "context": {...}}
```

---

</p></details>

<details><summary><strong>Tagging logs</strong></summary><p>

Tags provide a quick way to categorize logs and make them easier to search:

```elixir
Logger.info("My log message", tags: ["tag"])

# My log message @metadata {"level": "info", "tags": ["tag"], "context": {...}}
```

* In the [Timber console](https://app.timber.io) use the query: `tags:tag`.

---

</p></details>

<details><summary><strong>Timings</strong></summary><p>

Timings allow you to capture code execution time:

```elixir
timer = Timber.start_timer()
# ... code to time ...
time_ms = Timber.duration_ms(timer)
Logger.info("Task complete", tags: ["my_task"] time_ms: time_ms)

# Task complete @metadata {"level": "info", "tags": ["my_task"], "time_ms": 56.4324, "context": {...}}
```

* In the [Timber console](https://app.timber.io) use the query: `tags:my_task time_ms>500`

---

</p></details>

<details><summary><strong>Custom events</strong></summary><p>

Before logging a custom event, checkout [`Timber.Events`](lib/timber/events) to make sure it doesn't
already exist.

Custom events allow you to capture events central to your line of business like receiving
credit card payments, saving a draft of a post, or changing a user's password:

1. Log a map (simplest)

  ```elixir
  event_data = %{customer_id: "xiaus1934", amount: 1900, currency: "USD"}
  Logger.info("Payment rejected", event: %{payment_rejected: event_data})

  # Payment rejected @metadata {"level": "warn", "event": {"payment_rejected": {"customer_id": "xiaus1934", "amount": 100, "reason": "Card expired"}}, "context": {...}}
  ```

2. Or, log a struct (recommended)

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

  # Payment rejected @metadata {"level": "warn", "event": {"payment_rejected": {"customer_id": "xiaus1934", "amount": 100, "reason": "Card expired"}}, "context": {...}}
  ```

* In the [Timber console](https://app.timber.io) use the query:
  `payment_rejected.customer_id:xiaus1934` or `payment_rejected.amount>100`


#### What about regular Hashes, JSON, or logfmt?

Go for it! Timber will parse the data server side. If the event is meaningful in any way we
_highly_ recommend using custom events (see above).

```ruby
Logger.info(%{key: "value"})
# {"key": "value"} @metadata {"level": "info", "context": {...}}

Logger.info('{"key": "value"}')
# {"key": "value"} @metadata {"level": "info", "context": {...}}

Logger.info("key=value")
# key=value @metadata {"level": "info", "context": {...}}
```

* In the [Timber console](https://app.timber.io) use the query: `key:value`

---

</p></details>

<details><summary><strong>Custom contexts</strong></summary><p>

Context is additional data shared across log lines. Think of it like log join data.

1. Add a map (simplest)

  ```elixir
  Timber.add_context(%{build: %{version: "1.0.0"}})
  Logger.info("My log message")

  # My log message @metadata {"level": "info", "context": {"build": {"version": "1.0.0"}}}
  ```

2. Add a struct (recommended)

  ```elixir
  def BuildContext do
    use Timber.Contexts.CustomContext, type: :build
    @enforce_keys [:version]
    defstruct [:version]
  end

  Timber.add_context(%BuildContext{version: "1.0.0"})
  Loger.info("My log message")

  # My log message @metadata {"level": "info", "context": {"build": {"version": "1.0.0"}}}
  ```

* In the [Timber console](https://app.timber.io) use the query: `build.version:1.0.0`

</p></details>


## Jibber-Jabber

<details><summary><strong>Which log events does Timber structure for me?</strong></summary><p>

Out of the box you get everything in the [`Timber.Events`](lib/timber/events) namespace.

We also add context to every log, everything in the [`Timber.Contexts`](lib/timber/contexts)
namespace. Context is structured data representing the current environment when the log line
was written. It is included in every log line. Think of it like join data for your logs.

---

</p></details>

<details><summary><strong>What about my current log statements?</strong></summary><p>

They'll continue to work as expected. Timber adheres strictly to the default `Logger` interface
and will never deviate in *any* way.

In fact, traditional log statements for non-meaningful events, debug statements, etc, are
encouraged. In cases where the data is meaningful, consider [logging a custom event](#usage).

</p></details>

<details><summary><strong>How is Timber different?</strong></summary><p>

1. **No lock-in**. Timber is just _better_ logging. There are no agents or special APIs. This means
   no risk of vendor lock-in, code debt, or performance issues.
2. **Data quality.** Instead of relying on parsing alone, Timber ships libraries that structure
   and augment your logs from _within_ your application. Improving your log data at the source.
3. **Human readability.** Structuring your logs doesn't have to mean losing readability. Instead,
   Timber _augments_ them. For example: `log message @metadata {...}`. And when you view them in the
   [Timber console](https://app.timber.io), you'll see human friendly messages with the ability
   to view the attached metadata.
4. **Sane prices, long retention**. Logging is notoriously expensive with low retention. Timber
   is affordable and offers 6 months of retention by default.
5. **Normalized schema.** Have multiple apps? All of Timber's libraries adhere to our
   [JSON schema](https://github.com/timberio/log-event-json-schema). This means queries, alerts,
   and graphs for your ruby app can also be applied to your elixir app (for example).

---

</p></details>

---

<p align="center" style="background: #221f40;">
<a href="http://github.com/timberio/timber-elixir"><img src="http://files.timber.io/images/ruby-library-readme-log-truth.png" height="947" /></a>
</p>
