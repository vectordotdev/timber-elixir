# 🌲 Timber - Log Better. Solve Problems Faster.

[![ISC License](https://img.shields.io/badge/license-ISC-ff69b4.svg)](LICENSE.md)
[![Hex.pm](https://img.shields.io/hexpm/v/timber.svg?maxAge=18000=plastic)](https://hex.pm/packages/timber)
[![Documentation](https://img.shields.io/badge/hexdocs-latest-blue.svg)](https://hexdocs.pm/timber/index.html)
[![Build Status](https://travis-ci.org/timberio/timber-elixir.png?branch=master)](https://travis-ci.org/timberio/timber-elixir)

* [Timber website](https://timber.io)
* [Timber docs](https://timber.io/docs)
* [Library docs](https://hexdocs.pm/timber/readme.html)
* [Support](mailto:support@timber.io)

## Overview

[Timber](https://timber.io) is the logging platform we always wanted. It's the first logging
platform to integrate directly with your application. Instead of parsing, Timber integrates with
the standard Elixir `Logger`, capturing context and metadata you couldn't otherwise. It
automatically transforms your messy raw text logs into insanely useful structured events with
context.

1. [**Easy setup** - `mix timber.install`](#installation)
2. [**Seamlessly integrates with popular libraries and frameworks**](#jibber-jabber)
3. [**Modern fast console, designed specifically for your application:**](#the-timber-console)


## Installation

1. Add `timber` as a dependency in `mix.exs`:

    ```elixir
    # Mix.exs

    def application do
      [applications: [:timber]]
    end

    def deps do
      [{:timber, "~> 2.1"}]
    end
    ```

2. In your `shell`, run `mix deps.get`.

3. In your `shell`, run `mix timber.install`.


## Usage

<details><summary><strong>Basic text logging</strong></summary><p>

No special API, Timber works directly with `Logger`:

```elixir
Logger.info("My log message")

# => My log message @metadata {"level": "info", "context": {...}}
```

---

</p></details>

<details><summary><strong>Structured logging (metadata)</strong></summary><p>

Simply use Elixir's native Logger metadata:

```elixir
Logger.info("Payment rejected", customer_id: "abcd1234", amount: 100, currency: "USD")

# => My log message @metadata {"level": "info", "meta": {"customer_id": "abcd1234", "amount": 100}}
```

* In the [Timber console](https://app.timber.io) use the queries like `customer_id:abcd1234` or `amount:>100`.
* **Warning:** metadata keys must use consistent types as the values. If `customer_id` key was
  sent an integer, it would not be indexed because it was first sent a string. See the
  "Custom events" example below if you'd like to avoid this.
  See [when to use metadata or events](#jibber-jabber).

---

</p></details>

<details><summary><strong>Custom events</strong></summary><p>

Events are just defined structures with a namespace. They are more formal and avoid type collisions.
Custom events, specifically, allow you to extend beyond events already defined in
the [`Timber.Events`](lib/timber/events) namespace.

```elixir
event_data = %{customer_id: "xiaus1934", amount: 1900, currency: "USD"}
Logger.info("Payment rejected", event: %{payment_rejected: event_data})

# => Payment rejected @metadata {"level": "warn", "event": {"payment_rejected": {"customer_id": "xiaus1934", "amount": 100, "reason": "Card expired"}}, "context": {...}}
```

* In the [Timber console](https://app.timber.io) use the queries like `type:payment_rejected` or `payment_rejected.amount:>100`.
* See [when to use metadata or events](#jibber-jabber)

---

</p></details>

<details><summary><strong>Custom contexts</strong></summary><p>

Context is additional data shared across log lines. Think of it like log join data.
It's stored in the local process dictionary and is incldued in every log written
within that process. Custom contexts allow you to extend beyond contexts already
defined in the [`Timber.Contexts`](lib/timber/contexts) namespace.

```elixir
Timber.add_context(build: %{version: "1.0.0"})
Logger.info("My log message")

# => My log message @metadata {"level": "info", "context": {"build": {"version": "1.0.0"}}}
```

* Notice the `:build` root key. Timber will classify this context as such.
* In the [Timber console](https://app.timber.io) use the query `build.version:1.0.0`

</p></details>

<details><summary><strong>Metrics</strong></summary><p>

Logging metrics is accomplished by logging custom events. Please see our
[metrics docs page](https://timber.io/docs/elixir/metrics/) for a more detailed explanation
with examples.

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

<details><summary><strong>When to use metadata or events?</strong></summary><p>

At it's basic level, both metadata and eventa serve the same purpose: they add structured
data to your logs. And anyone that's implemented structured logging know's this can quickly get
out of hand. This is why we created events. Here's how we recommend using them:

1. Use `events` when the log cleanly maps to an event that is core to your business. Something
   that you'd like to alert on, graph, or use in a meaningful way.
2. Use metadata for debugging purposes; when you simply want additional insight without
   polluting the message.

### Example: Logging that a payment was rejected

This is clearly an event that is meaningful to your business. You'll probably want to alert and
graph this data. So let's log it as an official event:

```elixir
event_data = %{customer_id: "xiaus1934", amount: 1900, currency: "USD"}
Logger.info("Payment rejected", event: %{payment_rejected: event_data})
```

### Example: Gaining additional insight before an error occurs

This is not an event, but it is helpful data. Let's add it as metadata so that we don't pollute
the message, ensuring the log is reable:

```elixir
Logger.info("Received parameters", parameters: %{key: "val"})
```

---

</p></details>


## The Timber Console

[![Timber Console](http://files.timber.io/images/readme-interface7.gif)](https://app.timber.io)

## The Timber Lumberjack

<p align="center" style="background: #221f40;">
<a href="http://github.com/timberio/timber-elixir"><img src="http://files.timber.io/images/readme-log-truth.png" height="947" /></a>
</p>
