# Upgrading

This documents outlines how to upgrade from major versions of Timber

## 2.0 to 2.1

Custom HTTP clients have been deprecated as of version 2.1.0. You can remove the
`:http_client` key from any Timber configuration. For example, the following:

```elixir
config :timber,
  api_key: "123",
  http_client: Timber.HTTPClients.Hackney
```

can become:

```elixir
config :timber,
  api_key: "123"
```

## 1.x to 2.X

The 2.X introduces a number of enhancements and improvements. You can read more about the
new 2.X line [here](https://timber.io/changelog/2017/03/31/timber-for-elixir-2-0/).

To upgrade, please follow these steps:

1. Delete `config/timber.exs`

2. Re-run the single command installer: `mix timber.install <your-api-key>`.
   You can locate your api key by following this guide:
   https://timber.io/docs/app/advanced/api-keys/

If you have *any* issue, please reach out to us: support@timber.io
