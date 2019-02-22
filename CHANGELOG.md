# Changelog

This covers changes for versions 3.0 and higher. The changelog for 2.x releases
can be found in the [v2.x
branch](https://github.com/timberio/timber-elixir/blob/v2.x/CHANGELOG.md).

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic
Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

  - `Timber.InvalidAPIKeyError` is now `Timber.Errors.InvalidAPIKeyError`
  - Events are no longer nested under the `event` key.
  - Custom events are no longer nested under the `event.custom` key, they have simply been moved
    to the root of the document.
  - Custom contexts are no longer nested under the `context.custom` key, they have simply been
    moved to the root of the document.
  - JSON representations of log events no longer include the `$schema` key since Timber 2.0
    does not strictly require a schema anymore.
  - All `Timber.Events.*` and `Timber.Contexts.*` structs have been deprecated in favor of
    simple maps since Timber 2.0 no longer requires a strict schema. Module docs for each
    module has been updated accordingly.
  - Errors are no longer automatically parsed in the logger backend. Please use the
    [`:timber_exceptions`](https://github.com/timberio/timber-elixir-exceptions) library if you'd
    like to structure errors. This is a proper approach to structuring these events.

## 3.0.0 - 2018-12-20

3.0.0 contains breaking changes, for upgrade instructions see [UPGRADING.md](./UPGRADING.md)

### Changed

  - [Jason](https://hex.pm/packages/jason) is now used for JSON encoding. The
    JSON library can no longer be injected via configuration.
  - [`msgpax`](https://hex.pm/packages/msgpax) 1.x is no longer supported
  - Logs are now sent in batches of 1000 instead of 5000 to comply with the
  Timber library specification
  - `Timber.LoggerBackends.HTTP.TimberAPIKeyInvalid` is now `Timber.InvalidAPIKeyError`

### Removed

  - Removed support for Elixir 1.3 and lower
  - Removed integration with Phoenix; use the
    [`:timber_phoenix`](https://hex.pm/packages/timber_phoenix) package instead
  - Removed integration with Plug; use the
    [`:timber_plug`](https://hex.pm/packages/timber_plug) package instead
  - Removed integration with Ecto; use the
    [`:timber_ecto`](https://hex.pm/packages/timber_ecto) package instead
  - Removed integration with ExAws
  - Removed integration with `:error_logger`; use the
    [`:timber_exceptions`](https://hex.pm/packages/timber_exceptions) package
    instead
  - Removed the installer (`mix timber.install`); manual installation is now
    expected
  - Removed the test event Mix task

[Unreleased]: https://github.com/timberio/timber-elixir/compare/v3.0.0...HEAD
