# Timber.io - Powerful Elixir Logging

<p align="center" style="background: #140f2a;">
<a href="http://github.com/timberio/timber-ruby"><img src="http://res.cloudinary.com/timber/image/upload/c_scale,w_537/v1464797600/how-it-works_sfgfjp.gif" /></a>
</p>

[![ISC License](https://img.shields.io/badge/license-ISC-ff69b4.svg)](LICENSE) [![Hex.pm](https://img.shields.io/hexpm/v/timber.svg?maxAge=18000=plastic)](https://hex.pm/packages/timber) [![Documentation](https://img.shields.io/badge/hexdocs-latest-blue.svg)](https://hexdocs.pm/timber/index.html) [![CircleCI branch](https://img.shields.io/circleci/project/timberio/timber-elixir/master.svg?maxAge=18000=plastic)](https://circleci.com/gh/timberio/timber-elixir/tree/master) [![Coverage Status](https://coveralls.io/repos/github/timberio/timber-elixir/badge.svg?branch=master)](https://coveralls.io/github/timberio/timber-elixir=master)

**Note: Timber is in alpha testing, if interested in joining, please visit http://timber.io**

[Timber](http://timber.io) is a different kind of logging platform; it goes beyond traditional
logging by enriching your logs with application level context, turning them into rich, structured
events without altering the essence of logging. See for yourself at [timber.io](http://timber.io).

Timber for Elixir works with the standard Elixir Logger system. No wrappers. No jury-rigging.
No need to rewrite all your log statements. Just call `Logger.info` (or whichever level you
prefer) and Logger will coordinate everything else with Timber. Even better, Timber will
work alongside any other Elixir Logger backend you have installed.

## Installation

To get started, you'll need to add Timber to your application dependencies:

```elixir
def application do
  [applications: [:timber]]
end

def deps do
  [{:timber, "~> 0.1"}]
end
```

You will also need to declare Timber as an Elixir Logger backend in your application
configuration. Typically, this is done in `config/config.exs` for your codebase:

```elixir
config :logger, backends: [Timber.Logger]
```

Note that the backends key is defined as a list. Timber complies with the expectations
of any other Logger backend and can run alongside other backends without interfering.
This is helpful if you use our HTTP transport method but still want to use the default
`:console` backend to see logs locally.

## Transport Configuration

The last step to make the Timber library work is to tell it how you want to communicate with Timber's servers.
We call this the "transport strategy." Currently, our only available strategy is to use `stdout` in combination
with Heroku's Logplex system. In the future we'll also be offering HTTP transport strategies and more based
on consumer demand.

### Heroku Logplex

If you deploy to Heroku, it's very simple to get started. You'll need to declare in your application configuration
that you want to use the `IODevice` transport without timestamps (since Heroku adds timestamps automatically).

```elixir
config :timber, :transport, Timber.Transports.IODevice
config :timber, :transport_config, print_timestamps: false
```

Separately, you'll need to add your unique log drain URL to Heroku for your application:

```shell
heroku drains:add https://<timber-api-key>@api.timber.io/heroku/logplex_frames --app <app-name>
```

Make sure to replace `<timber-api-key>` with your Timber API key (found on your Timber dashboard)
and `<app-name>` with the name of the application on Heroku.

You're done!

## Improving the Context

Out of the box, Timber knows how to collect some specific information about your system, like
Phoenix and Plug HTTP requests, but it needs to be wired into the right places. We make this
as simple as possible so that you can get up-and-running with very little work.

### Plug & Phoenix

Plug, and frameworks like Phoenix which are based on it, can provide information to Timber about
HTTP requests and repsonses if you insert the `Timber.Plug` plug into your pipeline. The most
simple example is adding it to a pipeline in a Phoenix router:

```elixir
defmodule MyApp.Router do
  use MyApp.Web, :router

  pipeline :logging do
    plug Timber.Plug
  end

  scope "/api", MyApp do
    pipe_through :logging
  end
end
```

Any of your scopes piped through the `:logging` pipeline will now have their
context automatically collected by Timber. You can also add Timber to an
existing pipeline or pass multiple pipeliness to `Phoenix.Router.pipe_through/1`.

### Ecto

Timber can collect information about the queries Ecto runs if you declare
Timber as one of Ecto's loggers. This only requires a minor configuration
change:

```elixir
config :my_app, MyApp.Repo,
  loggers: [{Timber.Ecto, :add_context, []}, {Ecto.LogEntry, :log, []}]
```

Now any query information will be added to your context information.

The `:loggers` configuration key is a special feature from Ecto that
informs listed "loggers" of query events. Timber won't actually write
out a log, it will just capture the context information for future
logs.

### Additional Contexts

For everything that we don't provide a context plugin for, we try to make it simple to add
more context to your application logs. We have a number of structure contexts which we
predefine, but you can also use the freeform `CustomContext` type to define your own.

For more information, make sure to checkout [the documentation]().

