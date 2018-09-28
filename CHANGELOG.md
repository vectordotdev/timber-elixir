# Changelog

This covers changes for versions 3.0 and higher. The changelog for 2.x releases
can be found in the [v2.x
branch](https://github.com/timberio/timber-elixir/blob/v2.x/CHANGELOG.md).

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic
Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Removed

  - Removed support for Elixir 1.3 and lower
  - Removed integration with Phoenix; use the [`:timber_phoenix`](https://hex.pm/packages/timber_phoenix) package instead
  - Removed integration with Plug; use the [`:timber_plug`](https://hex.pm/packages/timber_plug) package instead
  - Removed integration with Ecto; use the [`:timber_ecto`](https://hex.pm/packages/timber_ecto) package instead
  - Removed integration with ExAws
  - Removed integration with `:error_logger`; use the [`:timber_exceptions`](https://hex.pm/packages/timber_exceptions) package instead
  - Removed the installer (`mix timber.install`); manual installation is now expected
  - Removed the test event Mix task

[Unreleased]: https://github.com/timberio/timber-elixir/compare/v2.x...HEAD
