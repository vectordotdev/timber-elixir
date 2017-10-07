# 🌲 Timber - Great Elixir Logging Made Easy

[![ISC License](https://img.shields.io/badge/license-ISC-ff69b4.svg)](LICENSE.md)
[![Hex.pm](https://img.shields.io/hexpm/v/timber.svg?maxAge=18000=plastic)](https://hex.pm/packages/timber)
[![Documentation](https://img.shields.io/badge/hexdocs-latest-blue.svg)](https://hexdocs.pm/timber/index.html)
[![Build Status](https://travis-ci.org/timberio/timber-elixir.svg?branch=master)](https://travis-ci.org/timberio/timber-elixir)


Timber for Elixir is a drop in backend for the Elixir `Logger` that
[unobtrusively augments](https://timber.io/docs/concepts/structuring-through-augmentation) your
logs with [rich metadata and context](https://timber.io/docs/concepts/metadata-context-and-events)
making them [easier to search, use, and read](#get-things-done-with-your-logs). It pairs with the
[Timber console](#the-timber-console) to deliver a tailored Elixir logging experience designed to make
you more productive.

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
      [{:timber, "~> 2.5"}]
    end
    ```

2. In your `shell`, run `mix deps.get && mix timber.install`.


## Usage

<details><summary><strong>Basic text logging</strong></summary><p>

The Timber library works directly with the standard Elixir
[Logger](https://hexdocs.pm/logger/Logger.html) and installs itself as a
[backend](https://hexdocs.pm/logger/Logger.html#module-backends) during the setup process.
In this way, basic logging is no different than logging without Timber:

```elixir
Logger.debug("My log statement")
Logger.info("My log statement")
Logger.warn("My log statement")
Logger.error("My log statement")
```

* [Search it](https://timber.io/docs/app/console/searching) with queries like: `error message`
* [Alert on it](https://timber.io/docs/app/console/alerts) with threshold based alerts
* [View this event's metadata and context](https://timber.io/docs/app/console/view-metadata-and-context)

[...read more in our docs](https://timber.io/docs/languages/elixir/usage/basic-logging)


---

</p></details>

<details><summary><strong>Logging events (structured data)</strong></summary><p>

Log structured data without sacrificing readability:

```elixir
event_data = %{customer_id: "xiaus1934", amount: 1900, currency: "USD"}
Logger.info("Payment rejected", event: %{payment_rejected: event_data})
```

* [Search it](https://timber.io/docs/app/console/searching) with queries like: `type:payment_rejected` or `payment_rejected.amount:>100`
* [Alert on it](https://timber.io/docs/app/console/alerts) with threshold based alerts
* [View this event's data and context](https://timber.io/docs/app/console/view-metadata-and-context)

...[read more in our docs](https://timber.io/docs/languages/elixir/usage/custom-events)

---

</p></details>

<details><summary><strong>Setting context</strong></summary><p>

Add shared structured data across your logs:

```elixir
Timber.add_context(build: %{version: "1.0.0"})
Logger.info("My log message")
```

* [Search it](https://timber.io/docs/app/console/searching) with queries like: `job.id:123`
* [View this context when viewing a log's metadata](https://timber.io/docs/app/console/view-metadata-and-context)

...[read more in our docs](https://timber.io/docs/languages/elixir/usage/custom-context)

---

</p></details>


### Pro-tips 💪

<details><summary><strong>Timings & Metrics</strong></summary><p>

Time code blocks:

```elixir
timer = Timber.start_timer()
# ... code to time ...
Logger.info("Processed background job", event: %{background_job: %{time_ms: timer}})
```

Log generic metrics:

```elixir
Logger.info("Processed background job", event: %{background_job: %{time_ms: 45.6}})
```

* [Search it](https://timber.io/docs/app/console/searching) with queries like: `background_job.time_ms:>500`
* [Alert on it](https://timber.io/docs/app/console/alerts) with threshold based alerts
* [View this log's metadata in the console](https://timber.io/docs/app/console/view-metadata-and-context)

...[read more in our docs](https://timber.io/docs/languages/elixir/usage/metrics-and-timings)

---

</p></details>

<details><summary><strong>Tracking background jobs</strong></summary><p>

*Note: This tip refers to traditional background jobs backed by a queue. For native Elixir
processes we capture the `context.runtime.vm_pid` automatically. Calls like `spawn/1` and
`Task.async/1` will automatially have their `pid` included in the context.*

For traditional background jobs backed by a queue you'll want to capture relevant
job context. This allows you to segement logs by specific jobs, making it easy to debug and
monitor your job executions. The most important attribute to capture is the `id`:

```elixir
%Timber.Contexts.JobContext{queue_name: "my_queue", id: "abcd1234", attempt: 1}
|> Timber.add_context()

Logger.info("Background job execution started")
# ...
Logger.info("Background job execution completed")
```

* [Search it](https://timber.io/docs/app/console/searching) with queries like: `background_job.time_ms:>500`
* [Alert on it](https://timber.io/docs/app/console/alerts) with threshold based alerts
* [View this log's metadata in the console](https://timber.io/docs/app/console/view-metadata-and-context)

...[read more in our docs](https://timber.io/docs/languages/elixir/usage/tracking-background-jobs)

---

</p></details>

<details><summary><strong>Track communication with external services</strong></summary><p>

We use this trick internally at Timber to track communication with external services.
It logs requests and responses to external services, giving us insight into response times and
failed requests.

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

* [Search it](https://timber.io/docs/app/console/searching) with queries like: `background_job.time_ms:>500`
* [Alert on it](https://timber.io/docs/app/console/alerts) with threshold based alerts
* [View this log's metadata in the console](https://timber.io/docs/app/console/view-metadata-and-context)

...[read more in our docs](https://timber.io/docs/languages/elixir/usage/track-external-service-communication)

---

</p></details>

<details><summary><strong>Adding metadata to errors</strong></summary><p>

By default, Timber will capture and structure all of your errors and exceptions, there
is nothing additional you need to do. You'll get the exception `message`, `name`, and `backtrace`.
But, in many cases you need additional context and data. Timber supports additional fields
in your exceptions, simply add fields as you would any other struct.

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

* [Search it](https://timber.io/docs/app/console/searching) with queries like: `background_job.time_ms:>500`
* [Alert on it](https://timber.io/docs/app/console/alerts) with threshold based alerts
* [View this log's metadata in the console](https://timber.io/docs/app/console/view-metadata-and-context)

...[read more in our docs](https://timber.io/docs/languages/elixir/usage/adding-metadata-to-errors)

---

</p></details>

<details><summary><strong>Sharing context between processes</strong></summary><p>

The `Timber.Context` is local to each process, this is by design as it prevents processes from
conflicting with each other as they maintain their contexts. But many times you'll want to share
context between processes because they are related (such as processes created by `Task` or `Flow`).
In these instances copying the context is easy.

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

* [Search it](https://timber.io/docs/app/console/searching) with queries like: `background_job.time_ms:>500`
* [Alert on it](https://timber.io/docs/app/console/alerts) with threshold based alerts
* [View this log's metadata in the console](https://timber.io/docs/app/console/view-metadata-and-context)

...[read more in our docs](https://timber.io/docs/languages/elixir/usage/sharing-context-between-processes)


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

* Frameworks & Libraries
  * [**Phoenix**](https://timber.io/docs/languages/elixir/integrations/phoenix)
  * [**Ecto**](https://timber.io/docs/languages/elixir/integrations/ecto)
  * [**Plug**](https://timber.io/docs/languages/elixir/integrations/plug)
* Platforms
  * [**System / Server**](https://timber.io/docs/languages/elixir/integrations/system)

...more coming soon! Make a request by [opening an issue](https://github.com/timberio/timber-elixir/issues/new)


## Get things done with your logs

Logging features every developer needs:

* [**Powerful searching.** - Find what you need faster.](https://timber.io/docs/app/console/searching)
* [**Live tail users.** - Easily solve customer issues.](https://timber.io/docs/app/console/tail-a-user)
* [**View logs per HTTP request.** - See the full story without the noise.](https://timber.io/docs/app/console/trace-http-requests)
* [**Inspect HTTP request parameters.** - Quickly reproduce issues.](https://timber.io/docs/app/console/inspect-http-requests)
* [**Threshold based alerting.** - Know when things break.](https://timber.io/docs/app/alerts)

...and more! Checkout our [the Timber application docs](https://timber.io/docs/app)


## The Timber Console

[![Timber Console](http://files.timber.io/images/readme-interface7.gif)](https://app.timber.io)

[Learn more about our app.](https://timber.io/docs/app)


## Your Moment of Zen

<p align="center" style="background: #221f40;">
<a href="https://timber.io"><img src="http://files.timber.io/images/readme-log-truth.png" height="947" /></a>
</p>
