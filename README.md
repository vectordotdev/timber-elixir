# 🌲 Timber - Log Better. Solve Problems Faster.

[![ISC License](https://img.shields.io/badge/license-ISC-ff69b4.svg)](LICENSE.md)
[![Hex.pm](https://img.shields.io/hexpm/v/timber.svg?maxAge=18000=plastic)](https://hex.pm/packages/timber)
[![Documentation](https://img.shields.io/badge/hexdocs-latest-blue.svg)](https://hexdocs.pm/timber/index.html)
[![Build Status](https://travis-ci.org/timberio/timber-elixir.svg?branch=master)](https://travis-ci.org/timberio/timber-elixir)

## Overview

[Timber](https://timber.io) is a logging platform with one major difference: Instead of parsing,
which relies on unreadable, unpredictable, hard to use text logs, Timber integrates directly with
your application, producing rich structured events containing metadata and context you couldn't
capture otherwise. It fundamentally changes the way you use your logs.

1. [**Easy setup** - `mix timber.install`](#installation)
2. [**Seamlessly integrates with popular libraries and frameworks**](#jibber-jabber)
3. [**Modern fast console, designed specifically for your application**](#the-timber-console)


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
Logger.info("Payment rejected", meta: %{customer_id: "abcd1234", amount: 100, currency: "USD"})

# => My log message @metadata {"level": "info", "meta": {"customer_id": "abcd1234", "amount": 100}}
```

* In the [Timber console](https://app.timber.io) use the queries like `customer_id:abcd1234` or `amount:>100`.
* **Warning:** metadata keys must use consistent types as the values. If `customer_id` key was
  sent an integer, it would not be indexed because it was first sent a string. See the
  "Custom events" example below if you'd like to avoid this.
  See [when to use metadata or events](#jibber-jabber).
* Note: the `:meta` key is necessary until
  [this recent change](https://github.com/elixir-lang/elixir/commit/fe283748b9e7bcc40a118a30f57d3614d1c8e069)
  to the Elixir logger makes it into an official release.

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

---

</p></details>

<details><summary><strong>Metrics</strong></summary><p>

Logging metrics is accomplished by logging custom events. Please see our
[metrics docs page](https://timber.io/docs/elixir/metrics/) for a more detailed explanation
with examples.

---

</p></details>

<details><summary><strong>Adding metadata to your errors</strong></summary><p>

By default, Timber will capture and structure all of your errors and exceptions, there
is nothing additional you need to do. You'll get the exception message, name, and backtrace.
But, in many cases you need additional context and data. Timber supports additional fields
in your exceptions, simply add fields as you would any other struct:

```elixir
defmodule StripeCommunicationError do
  defexception [:message, :customer_id, :card_token, :stripe_response]
end

raise(
  StripeCommunicationError,
  message: "Bad response #{response} from Stripe!",
  customer_id: "xiaus1934",
  card_token: "mwe42f64",
  stripe_response: response_body
)
```

* Run the query `type:error` to view all errors.
* Within the [Timber console](https://app.timber.io) you can click the log to view all of this data.

---

</p></details>

<details><summary><strong>Searching, graphing, alerting, etc</strong></summary><p>

Checkout the official [Timber console docs](https://timber.io/docs/app/overview/). It walks you through
everything from our search syntax to alerting and graphin.

---

</p></details>


## Integrations

<details><summary><strong>Phoenix</strong></summary><p>

The [`Phoenix` integration](https://hexdocs.pm/timber/Timber.Integrations.PhoenixInstrumenter.html#content)
structures your existing `Phoenix` logs into
[`controller_call`](https://timber.io/docs/elixir/events-and-context/controller-call-event/) and
[`template_render`](https://timber.io/docs/elixir/events-and-context/template-render-event/) events.

Pro-tip: this integration captures the parameters sent to your controller, making it easy to
debug issues by understanding exactly which data was sent to your controller.


### Installation

To install this integration, please run the `mix timber.install` command as noted in the
[installation section](#installation). For manual installation, please see the
[`Timber.Integrations.PhoenixInstrumenter` docs](https://hexdocs.pm/timber/Timber.Integrations.PhoenixInstrumenter.html#content).

---

</p></details>

<details><summary><strong>Ecto</strong></summary><p>

The [`Ecto` integration](https://hexdocs.pm/timber/Timber.Integrations.EctoLogger.html#content)
structures your existing `Ecto` logs into structured
[`sql_query`](https://timber.io/docs/elixir/events-and-context/sql-query-event/) events.

Pro-tip: this integration captures SQL query times, making it easy to visualize SQL query
performance and find slow queries.

### Installation

To install this integration, please run the `mix timber.install` command as noted in the
[installation section](#installation). For manual installation, please see the
[`Timber.Integrations.EctoLogger` docs](https://hexdocs.pm/timber/Timber.Integrations.EctoLogger.html#content).

---

</p></details>

<details><summary><strong>Plug</strong></summary><p>

The [`Plug` integration](https://hexdocs.pm/timber/Timber.Integrations.EctoLogger.html#content)
structures your existing `Plug` logs into
[`http_request`](https://timber.io/docs/elixir/events-and-context/http-request-event/) and
[`http_response`](https://timber.io/docs/elixir/events-and-context/http-response-event/) events.

Pro-tip: this integration captures HTTP response codes and times, making it easy to visualize
the performance of your application.

### Installation

To install this integration, please run the `mix timber.install` command as noted in the
[installation section](#installation). For manual installation, please see the
[`Timber.Integrations.EventPlug`](https://hexdocs.pm/timber/Timber.Integrations.EventPlug.html#content),
[`Timber.Integrations.HTTPContextPlug`](https://hexdocs.pm/timber/Timber.Integrations.HTTPContextPlug.html#content),
and [`Timber.Integrations.SessionContextPlug`](https://hexdocs.pm/timber/Timber.Integrations.SessionContextPlug.html#content)
docs. We highly recommend using the installer!

---

</p></details>

<details><summary><strong>ExAws</strong></summary><p>

The [`ExAws` integration](https://hexdocs.pm/timber/Timber.Integrations.EctoLogger.html#content)
logs and structures AWS HTTP communication
[`http_request`](https://timber.io/docs/elixir/events-and-context/http-request-event/) and
[`http_response`](https://timber.io/docs/elixir/events-and-context/http-response-event/) events.


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

At it's basic level, both metadata and events serve the same purpose: they add structured
data to your logs. And anyone that's implemented structured logging know's this can quickly get
out of hand. This is why we created events. Here's how we recommend using them:

1. Use `events` when the log cleanly maps to an event that you'd like to alert on, graph, or use
   in a meaningful way. Typically something that is core to your business or application.
2. Use metadata for debugging purposes; when you simply want additional insight without
   polluting the message.

### Example 1: Logging that a payment was rejected

This is clearly an event that is meaningful to your business. You'll probably want to alert and
graph this data. So let's log it as an official event:

```elixir
event_data = %{customer_id: "xiaus1934", amount: 1900, currency: "USD"}
Logger.info("Payment rejected", event: %{payment_rejected: event_data})
```

### Example 2: Logging that an email was changed

This is definitely log worthy, but not something that is core to your business or application.
Instead of an event, use metadata:

```elixir
Logger.info("Email successfully changed", meta: %{old_email: old_email, new_email: new_email})
```

---

</p></details>


## The Timber Console

[![Timber Console](http://files.timber.io/images/readme-interface7.gif)](https://app.timber.io)

## Your Moment of Zen

<p align="center" style="background: #221f40;">
<a href="http://github.com/timberio/timber-elixir"><img src="http://files.timber.io/images/readme-log-truth.png" height="947" /></a>
</p>
