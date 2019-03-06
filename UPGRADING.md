# Upgrading

This documents outlines how to upgrade from major versions of Timber

## 2.x to 3.x

Timber 3.x ships with a new library structure, including removing all integrations with dependencies like Phoenix, Ecto, and Plug into their own packages.  This will allow for better dependency management and compilation guarantees.  Many of the changes were internal, but upgrading does require a handful changes.

### Update Timber

To start, simply update your Timber dep in mix.exs:

```elixir
{:timber, "~> 3.0"}
```

### Timber.Phoenix

```elixir
# mix.exs

{:timber_phoenix, "~> 1.0"}
```
```diff
# config/config.exs
-   instrumenters: [Timber.Integrations.PhoenixInstrumenter],
+   instrumenters: [Timber.Phoenix],
```

### Timber.Plug

```elixir
# mix.exs
{:timber_plug, "~> 1.0"}
```

```diff
# endpoint.ex (or wherever your Timber Plug modules are added)

# Add Timber plugs for capturing HTTP context and events
- plug Timber.Integrations.SessionContextPlug
- plug Timber.Integrations.HTTPContextPlug
- plug Timber.Integrations.EventPlug
+ plug Timber.Plug.SessionContext
+ plug Timber.Plug.HTTPContext
+ plug Timber.Plug.Event
```

### Timber.Ecto

If you are on Ecto 2:

```elixir
# mix.exs

{:timber_ecto, "~> 1.0"}
```

```diff
# config/config.exs
-   loggers: [{Timber.Integrations.EctoLogger, :log, []}]
+   loggers: [{Timber.Ecto, :log, []}]

-config :timber, Timber.Integrations.EctoLogger,
-   query_time_ms_threshold: 2_000 # 2 seconds

+config :timber_ecto,
+   query_time_ms_threshold: 2_000 # 2 seconds
```

If you are on Ecto 3:
```elixir
# mix.exs

{:timber_ecto, "~> 2.0"}
```

```diff
# config/config.exs
config :my_app, MyApp.Repo,
+   log: false
```

```diff
# lib/my_app/application.ex
def start(_type, _args) do
  # ...
+  :ok = :telemetry.attach(
+    "timber-ecto-query-handler",
+    [:my_app, :repo, :query],
+    &Timber.Ecto.handle_event/4,
+    []
+  )
  # ...
  Supervisor.start_link(children, opts)
end
```

### Timber.Exceptions

```elixir
# mix.exs

{:timber_exceptions, "~> 2.0"}
```

```diff
# application.ex
-:ok = :error_logger.add_report_handler(Timber.Integrations.ErrorLogger)
+:ok = Logger.add_translator({Timber.Exceptions.Translator, :translate})
```

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

## 1.x to 2.x

The 2.X introduces a number of enhancements and improvements. You can read more about the
new 2.X line [here](https://timber.io/changelog/2017/03/31/timber-for-elixir-2-0/).

To upgrade, please follow these steps:

1. Delete `config/timber.exs`

2. Re-run the single command installer: `mix timber.install <your-api-key>`.

If you have *any* issue, please reach out to us: support@timber.io
