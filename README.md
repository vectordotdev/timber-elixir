# 🌲 Timber - Simple & Reliable Elixir Logging

[![ISC License](https://img.shields.io/badge/license-ISC-ff69b4.svg)](LICENSE.md)
[![Hex.pm](https://img.shields.io/hexpm/v/timber.svg?maxAge=18000=plastic)](https://hex.pm/packages/timber)
[![Documentation](https://img.shields.io/badge/hexdocs-latest-blue.svg)](https://hexdocs.pm/timber/index.html)
[![Build Status](https://travis-ci.org/timberio/timber-elixir.svg?branch=master)](https://travis-ci.org/timberio/timber-elixir)

[Timber](timber) is a simple, reliable logging service with a focus on
high-quality, light-weight, thoughtful integrations. Timber integrates with
Elixir through this library.

## Getting Started

1. Signup at [Timber.io][signup] to get your API key.

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

Timber works with the Elixir logger and offers a mechanism for shared context:

```elixir
Timber.add_context(user: %{id: user_id})
Logger.info("Order ##{order_id} placed", order: %{id: order_id, total: total})
```

See more usage examples in [our documentation][docs].

## Integrations

Timber integrates with 3rd party libraries to automatically capture context
and metadata for the logs they emit:

* [`Ecto`](https://github.com/timberio/timber-elixir-ecto) - Add metadata to your `Ecto` logs.
* [`Phoenix`](https://github.com/timberio/timber-elixir-phoenix) - Add metadata to your `Phoenix` logs.
* [`Plug`](https://github.com/timberio/timber-elixir-plug) - Capture HTTP context and add metadata to your `Plug` logs.
* [`Exceptions`](https://github.com/timberio/timber-elixir-exceptions) - Add metadata to your logs when processes crash
* [Add your own&hellip;][integrating]

## Principles

If done properly, logs can be your most powerful observability tool. Core
tenents of Timber that deliver on this promise are:

1. Logs should be human readable.
2. [Logs should contain context][setting_context].
3. [Logs should contain structured data][structured_logging].
4. [Logs should be affordable.][pricing]

---

<p align="center">
<a href="/CONTRIBUTING.md">Contributing</a> &bull;
<a href="mailto:support@timber.io">Support</a> &bull;
<a href="https://timber.io">Timber.io</a>
</p>

[contributing]: /CONTRIBUTING.md
[docs]: https://docs.timber.io/integrations/elixir
[pricing]: https://timber.io/pricing
[setting_context]: /USAGE.md#setting-context
[structured_logging]: /USAGE.md#logging-structured-data
[integrating]: /INTEGRATING.md
[signup]: https://app.timber.io
[support]: mailto:support@timber.io
[timber]: https://timber.io
