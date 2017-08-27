# 🌲 Timber - Great Elixir Logging Made Easy

[![ISC License](https://img.shields.io/badge/license-ISC-ff69b4.svg)](LICENSE.md)
[![Hex.pm](https://img.shields.io/hexpm/v/timber.svg?maxAge=18000=plastic)](https://hex.pm/packages/timber)
[![Documentation](https://img.shields.io/badge/hexdocs-latest-blue.svg)](https://hexdocs.pm/timber/index.html)
[![Build Status](https://travis-ci.org/timberio/timber-elixir.svg?branch=master)](https://travis-ci.org/timberio/timber-elixir)

[Timber](https://timber.io) is a cloud-based logging system that integrates directly with your Elixir
app through this library, capturing context and metadata without parsing. This produces rich, clean,
readable logs that are easier to search and use:

1. [**Installation** - One command: `mix timber.install`](#installation)
2. [**Usage** - Simple yet powerful API](#usage)
3. [**Integrations** - Automatic context and metadata for your existing logs](#integrations)
4. [**The Timber Console** - Designed for Elixir developers](#the-timber-console)
5. [**Get things done with your logs 💪**](#get-things-done-with-your-logs)


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

The Timber library works directly with the standard Elixir
[Logger](https://hexdocs.pm/logger/Logger.html) and installs itself as a
[backend](https://hexdocs.pm/logger/Logger.html#module-backends) during the setup process.
In this way, basic logging is no different than logging without Timber.

In fact, standard logging messages are encouraged for debug statements and non-meaningful events.
Timber does not require you to structure every log!


```elixir
Logger.debug("My log statement")
Logger.info("My log statement")
Logger.warn("My log statement")
Logger.error("My log statement")
```

---

</p></details>

<details><summary><strong>Logging events (structured data)</strong></summary><p>

Custom events allow you to extend beyond events already defined in
the [`Timber.Events`](https://hexdocs.pm/timber/Timber.Events.html#content) namespace. If you
aren't sure what an event is, please read the
["Metdata, Context, and Events" doc](https://timber.io/docs/concepts/metadata-context-and-events).

### How to use it

```elixir
event_data = %{customer_id: "xiaus1934", amount: 1900, currency: "USD"}
Logger.info("Payment rejected", event: %{payment_rejected: event_data})
```

1. [Search it](https://timber.io/docs/app/console/searching) with queries like: `type:payment_rejected` or `payment_rejected.amount:>100`
2. [Alert on it](https://timber.io/docs/app/alerts) with threshold based alerts.
3. [Graph & visualize it](https://timber.io/docs/app/graphs)
4. [View this event's data and context](https://timber.io/docs/app/console/view-metadata-and-context)
5. [Facet on this event type](https://timber.io/docs/app/console/faceting-your-logs)
3. ...read more in our [docs](https://timber.io/docs/languages/elixir/usage/custom-events)

---

</p></details>

<details><summary><strong>Setting context</strong></summary><p>

Custom contexts allow you to extend beyond contexts already defined in the
[`Timber.Contexts`](https://hexdocs.pm/timber/Timber.Contexts.html#content) namespace. If you
aren't sure what context is, please read the
["Metdata, Context, and Events" doc](/docs/concepts/metadata-context-and-events).

### How to use it

```elixir
Timber.add_context(build: %{version: "1.0.0"})
Logger.info("My log message")
```

1. [Search it](https://timber.io/docs/app/console/searching) with queries like: `build.version:1.0.0`
2. [View this context when viewing a log's metadata](https://timber.io/docs/app/console/view-metdata-and-context)
3. ...read more in our [docs](https://timber.io/docs/languages/elixir/usage/custom-context)

---

</p></details>


### Pro-tips 💪

<details><summary><strong>Timings & Metrics</strong></summary><p>

Aggregates destroy details, events tell stories. With Timber, logging metrics and timings is simply
[logging an event](https://timber.io/docs/languages/elixir/usage/custom-events). Timber is based on
modern big-data principles and can aggregate inordinately large data sets in seconds. Logging
events (raw data as it exists), gives you the flexibility in the future to segment and aggregate
your data any way you see fit. This is superior to choosing specific paradigms before hand, when
you are unsure how you'll need to use your data in the future.

### How to use it

Below is a contrived example of timing a background job:

```elixir
timer = Timber.start_timer()
# ... code to time ...
Logger.info("Processed background job", event: %{background_job: %{time_ms: timer}})
```

And of course, `time_ms` can also take a `Float` or `Fixnum`:

```elixir
Logger.info("Processed background job", event: %{background_job: %{time_ms: 45.6}})
```

Lastly, metrics aren't limited to timings. You can capture any metric you want:

```elixir
:ogger.info("Credit card charged", event: %{credit_card_charge: %{amount: 123.23}})
```

1. [Search it](https://timber.io/docs/app/console/searching) with queries like: `background_job.time_ms:>500`
2. [Alert on it](https://timber.io/docs/app/console/alerts) with threshold based alerts
3. [View this log's metadata in the console](https://timber.io/docs/app/console/view-metdata-and-context)
4. ...read more in our [docs](https://timber.io/docs/languages/elixir/usage/metrics-and-timings)

---

</p></details>

<details><summary><strong>Tracking background jobs and tasks</strong></summary><p>

*Note: This tip refers to traditional background jobs backed by a queue. For native Elixir
processes we capture the `context.runtime.vm_pid` automatically. Calls like `spawn/1` and
`Task.async/1` will automatially have their `pid` included in the context.*

For traditional background jobs backed by a queue you'll want to capture relevant
job context. This allows you to segement logs by specific jobs, making it easy to debug and
monitor your job executions. The most important attribute to capture is the `id`:


### How to use it

```elixir
%Timber.Contexts.JobContext{queue_name: "my_queue", id: "abcd1234", attempt: 1}
|> Timber.add_context()

Logger.info("Task execution started")
# ...
Logger.info("Task execution completed")
```

1. [Search it](https://timber.io/docs/app/console/searching) with queries like: `background_job.time_ms:>500`
2. [Alert on it](https://timber.io/docs/app/console/alerts) with threshold based alerts
3. [View this log's metadata in the console](https://timber.io/docs/app/console/view-metdata-and-context)
4. ...read more in our [docs](https://timber.io/docs/languages/elixir/usage/tracking-background-jobs-and-tasks)

---

</p></details>

<details><summary><strong>Track communication with external services</strong></summary><p>

We use this trick internally at Timber to track communication with external services.
It's gives us insight into response times and failed requests.

### How to use it

Below is a contrived example of submitting an invoice to Stripe.

```elixir
alias Timber.Events.HTTPRequestEvent
alias Timber.Events.HTTPResponseEvent

method = :get
url = "https://api.stripe.com/v1/invoices"
body = "{\"customer\": \"cus_BHhZyYRirFrPkz\"}"
headers = %{}

Logger.info fn ->
  event = HTTPRequestEvent.new(direction: "outgoing", service_name: "stripe", method: method, url: url, headers: headers, body: body)
  message = HTTPRequestEvent.message(event)
  {message, [event: event]}
end

case :hackney.request(method, url, headers, body, with_body: true) do
  {:ok, status, resp_headers, resp_body} ->
    Logger.info fn ->
      event = HTTPResponseEvent.new(direction: "incoming", service_name: "stripe", status: status, headers: resp_headers, body: resp_body)
      message = HTTPResponseEvent.message(event)
      {message, [event: event]}
    end

  {:error, error} ->
    message = Exception.message(error)
    Logger.error(message, event: error)
    {:error, error}
end

```

*Note: Only `method` is required for `HTTPRequestEvent`, and `status` for `HTTPResponseEvent`.
`body`, if logged, will be truncated to `2048` bytes for efficiency reasons. This can be adjusted
with [`Timber.Config.http_body_size_limit/0`](https://hexdocs.pm/timber/Timber.Config.html#http_body_size_limit/0).*

1. [Search it](https://timber.io/docs/app/console/searching) with queries like: `http_request.service_name:stripe`
2. [Alert on it](https://timber.io/docs/app/console/alerts) with threshold based alerts
3. [View this log's metadata in the console](https://timber.io/docs/app/console/view-metdata-and-context)
4. ...read more in our [docs](https://timber.io/docs/languages/elixir/usage/tracking-background-jobs-and-tasks)

---

</p></details>

<details><summary><strong>Adding metadata to errors</strong></summary><p>

By default, Timber will capture and structure all of your errors and exceptions, there
is nothing additional you need to do. You'll get the exception `message`, `name`, and `backtrace`.
But, in many cases you need additional context and data. Timber supports additional fields
in your exceptions, simply add fields as you would any other struct.


### How to use it

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

1. [Search it](https://timber.io/docs/app/console/searching) with queries like: `background_job.time_ms:>500`
2. [Alert on it](https://timber.io/docs/app/console/alerts) with threshold based alerts
3. [View this log's metadata in the console](https://timber.io/docs/app/console/view-metdata-and-context)
4. ...read more in our [docs](https://timber.io/docs/languages/elixir/usage/adding-metadata-to-errors)


---

</p></details>

<details><summary><strong>Sharing context between processes</strong></summary><p>

The `Timber.Context` is local to each process, this is by design as it prevents processes from
conflicting with each other as they maintain their contexts. But many times you'll want to share
context between processes because they are related (such as processes created by `Task` or `Flow`).
In these instances copying the context is easy.

### How to use it

```elixir
current_context = Timber.CurrentContext.load()

Task.async fn ->
  Timber.CurrentContext.save(current_context)
  Logger.info("Logs from a separate process")
end
```

`current_context` in the above example is captured in the parent process, and because Elixir's
variable scope is lexical, you can pass the referenced context into the newly created process.
`Timber.CurrentContext.save/1` copies that context into the new process dictionary.

---

</p></details>


## Configuration

Below are a few popular configuration options, for a comprehensive list see [Timber.Config](https://hexdocs.pm/timber/Timber.Config.html#content).

<details><summary><strong>Capture user context</strong></summary><p>

Capturing `user context` is a powerful feature that allows you to associate logs with users in
your application. This is great for support as you can
[quickly narrow logs to a specific user](https://timber.io/docs/app/console/tail-a-user), making
it easy to identify user reported issues.

### How to use it

Simply add the `UserContext` immediately after you authenticate the user:

```elixir
%Timber.Contexts.UserContext{id: "my_user_id", name: "John Doe", email: "john@doe.com"}
|> Timber.add_context()
```

All of the `UserContext` attributes are optional, but at least one much be supplied.

</p></details>

<details><summary><strong>Only log slow Ecto SQL queries</strong></summary><p>

Logging SQL queries can be useful but noisy. To reduce the volume of SQL queries you can
limit your logging to queries that surpass an execution time threshold:

### How to use it

```elixir
config :timber, Timber.Integrations.EctoLogger,
  query_time_ms_threshold: 2_000 # 2 seconds
```

In the above example, only queries that exceed 2 seconds in execution
time will be logged.

</p></details>


## Integrations

Timber integrates with popular frameworks and libraries to capture context and metadata you
couldn't otherwise. This automatically upgrades logs produced by these libraries, making them
[easier to search and use](#do-amazing-things-with-your-logs). Below is a list of libraries we
support:

1. [**Phoenix**](https://timber.io/docs/languages/elixir/integrations/phoenix)
2. [**Ecto**](https://timber.io/docs/languages/elixir/integrations/ecto)
3. [**Plug**](https://timber.io/docs/languages/elixir/integrations/plug)
4. ...more coming soon! Make a request by [opening an issue](https://github.com/timberio/timber-elixir/issues/new)


## Get things done with your logs

Logging features every developer needs:

1. [**Powerful searching.** - Find what you need faster.](https://timber.io/docs/app/console/searching)
2. [**Live tail users.** - Easily solve customer issues.](https://timber.io/docs/app/console/tail-a-user)
3. [**Viw logs per HTTP request.** - See the full story without the noise.](https://timber.io/docs/app/console/trace-http-requests)
4. [**Inspect HTTP request parameters.** - Quickly reproduce issues.](https://timber.io/docs/app/console/inspect-http-requests)
5. [**Threshold based alerting.** - Know when things break.](https://timber.io/docs/app/alerts)
6. ...and more! Checkout our [the Timber application docs](https://timber.io/docs/app)


## The Timber Console

[![Timber Console](http://files.timber.io/images/readme-interface7.gif)](https://app.timber.io)

[Learn more about our app.](https://timber.io/docs/app)


## Your Moment of Zen

<p align="center" style="background: #221f40;">
<a href="https://timber.io"><img src="http://files.timber.io/images/readme-log-truth.png" height="947" /></a>
</p>
