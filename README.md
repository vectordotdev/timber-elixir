# 🌲 Timber - Beautiful, Fast, Powerful Elixir Logging

[![ISC License](https://img.shields.io/badge/license-ISC-ff69b4.svg)](LICENSE.md)
[![Hex.pm](https://img.shields.io/hexpm/v/timber.svg?maxAge=18000=plastic)](https://hex.pm/packages/timber)
[![Documentation](https://img.shields.io/badge/hexdocs-latest-blue.svg)](https://hexdocs.pm/timber/index.html)
[![Build Status](https://travis-ci.org/timberio/timber-elixir.svg?branch=master)](https://travis-ci.org/timberio/timber-elixir)

[Timber.io][timber] is a hosted service for aggregating logs across your entire stack -
any language, any platform, any data source.

Unlike traditional logging tools, Timber integrates with language runtimes to automatically
capture in-app context and metadata, turning your text-based logs into rich structured events.
Timber integrates with Elixir through this library. And Timber's free-form query tools, real-time
tailing, and graphing make using your logs easier than ever.

The result: Beautiful, fast, powerful Elixir logging.

* [Getting started](#getting-started)
* [Usage](#usage)
* [Integrations](#integrations)
* [Performance & Reliability](#performance-reliability)

## Getting Started

1. Grab your API key at [Timber.io][signup].

2. In your `mix.exs` file add the `:timber` dependency:

    ```elixir
    defp deps do
      [{:timber, "~> 3.0"}]
    end
    ```

3. In your `config.exs` file install the Timber logger backend:

    ```elixir
    config :logger,
      backends: [Timber.LoggerBackends.HTTP],

    config :timber,
      api_key: "{{your-api-key}}"
    ```

## Usage

Timber works directly the Elixir `Logger`, making it fast and reliable:

```elixir
Timber.add_context(user: %{id: "5c06a0df5f37972e07cb7213"})
Logger.info("Order #1234 placed", event: %{order_placed: %{id: 1234, total: 100.54}})
```

Produces the following event:

```json
{
  "dt": "2019-01-29T17:11:48.992670Z",
  "level": "info",
  "message": "Order #1234 placed",
  "order_placed": {
    "id": 1234,
    "total": 100.54
  },
  "context": {
    "user": {
      "id": "5c06a0df5f37972e07cb7213"
    },
    "system": {
      "pid": 20643,
      "hostname": "ec2-44-125-241-8"
    },
    "runtime": {
      "vm_pid": "<0.9960.261>",
      "module_name": "MyModule",
      "line": 371,
      "function": "my_func/2",
      "file": "lib/my_app/my_module.ex",
      "application": "my_app"
    }
  }
}
```

Allowing you to run queries like:

* Tail a user: `context.user.id:5c06a0df5f37972e07cb7213`
* Find orders of a certain value: `order_placed.total:>=100`
* View logs in the context of the VM process: `context.runtime.vm_pid:"<0.9960.261>"`

See more usage examples in [our Elixir documentation][docs].

## Integrations

Extend Timber's context and metadata capture into 3rd party libraries:

* [`Ecto`](https://github.com/timberio/timber-elixir-ecto) - Augment `Ecto` logs with context and metadata.
* [`Exceptions`](https://github.com/timberio/timber-elixir-exceptions) - Augment errors with context and metadata.
* [`Phoenix`](https://github.com/timberio/timber-elixir-phoenix) - Augment `Phoenix` logs with context and metadata.
* [`Plug`](https://github.com/timberio/timber-elixir-plug) - Augment `Plug` logs with context and metadata.

## Performance & Reliability

Extreme care was taken into the design of Timber to be fast and reliable:

1. Timber works directly with the [Elixir `Logger`][elixir_logger], automatically assuming all of
   the [stability and performance benefits][elixir_logger_runtime_configuration] this provides,
   such as back pressure, load shedding, and defensability around `Logger` failures.
2. The Timber HTTP backend uses a [multi-buffer][multi_buffer] design to efficiently ship data
   to the Timber service.
3. Delivery failures are retried with an exponential backoff, maximizing successful delivery.
4. [Msgpack][msgpack] is used for payload encoding for it's superior performance and memory
   management.
5. The Timber service ingest endpoint is HA servce designed to handle extreme fluctuations of
   volume and responds in under 50ms.

---

<p align="center">
<a href="mailto:support@timber.io">Support</a> &bull;
<a href="https://timber.io">Timber.io</a>
</p>

[docs]: https://docs.timber.io/languages/elixir
[elixir_logger]: https://hexdocs.pm/logger/master/Logger.html
[elixir_logger_runtime_configuration]: https://hexdocs.pm/logger/master/Logger.html#module-runtime-configuration
[msgpack]: https://msgpack.org/index.html
[multi_buffer]: https://en.wikipedia.org/wiki/Multiple_buffering
[signup]: https://app.timber.io
[timber]: https://timber.io
