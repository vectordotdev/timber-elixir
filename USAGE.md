# Usage

## Basic text logging

The Timber library works directly with the standard Elixir
[Logger](https://hexdocs.pm/logger/Logger.html) and installs itself as a
[backend](https://hexdocs.pm/logger/Logger.html#module-backends) during the
setup process. In this way, basic logging is no different than logging without
Timber:

```elixir
Logger.debug("My log statement")
Logger.info("My log statement")
Logger.warn("My log statement")
Logger.error("My log statement")
```

## <a name="structured-events"></a>Logging events (structured data)

Log structured data without sacrificing readability:

```elixir
event_data = %{customer_id: "xiaus1934", amount: 1900, currency: "USD"}
Logger.info("Payment rejected", event: %{payment_rejected: event_data})
```

## <a name="setting-context"></a>Setting context

Add shared structured data across your logs:

```elixir
Timber.add_context(build: %{version: "1.0.0"})
Logger.info("My log message")
```

## Pro-tips 💪

Timings & Metrics

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

## Tracking background jobs

*Note: This tip refers to traditional background jobs backed by a queue. For
native Elixir processes we capture the `context.runtime.vm_pid` automatically.
Calls like `spawn/1` and `Task.async/1` will automatially have their `pid`
included in the context.*

For traditional background jobs backed by a queue you'll want to capture relevant
job context. This allows you to segemnt logs by specific jobs, making it easy to debug and
monitor your job executions. The most important attribute to capture is the `id`:

```elixir
%Timber.Contexts.JobContext{queue_name: "my_queue", id: "abcd1234", attempt: 1}
|> Timber.add_context()

Logger.info("Background job execution started")
# ...
Logger.info("Background job execution completed")
```

## Track communication with external services

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

timer = Timber.start_timer()
case :hackney.request(method, url, headers, body, with_body: true) do
  {:ok, status, resp_headers, resp_body} ->
    Logger.info fn ->
      event = HTTPResponseEvent.new(direction: "incoming", service_name: "stripe", status: status, headers: resp_headers, body: resp_body, time_ms: Timber.duration_ms(timer))
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

## Adding metadata to errors

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

## Sharing context between processes

The `Timber.Context` is local to each process, this is by design as it prevents processes from
conflicting with each other as they maintain their contexts. But many times you'll want to share
context between processes because they are related (such as processes created by [Task](https://hexdocs.pm/elixir/Task.html) or [Flow](https://hexdocs.pm/flow/Flow.html)).
In these instances copying the context is easy.

```elixir
current_context = Timber.LocalContext.get()

Task.async fn ->
  Timber.LocalContext.put(current_context)
  Logger.info("Logs from a separate process")
end
```

`current_context` in the above example is captured in the parent process, and because Elixir's
variable scope is lexical, you can pass the referenced context into the newly created process.
`Timber.LocalContext.put/1` copies that context into the new process dictionary.
