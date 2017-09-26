# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

  - Logger backends now conform to the `:gen_event` behaviour rather than calling
    the `GenEvent.__using__/1` macro which is deprecated in Elixir 1.5.0 and
    above. The change is backwards compatible since `:gen_event` is provided by
    all supported versions of Erlang.

## [2.5.5] - 2017-09-21

### Fixed

  - `Timber.Events.HTTPRepsonseEvent` no longer enforces the `:time_ms` key on
    the struct. This brings it in line with the specification

## [2.5.4] - 2017-09-18

### Fixed

  - Fixed a bug within the installer where HTTP log delivery was being used on platforms that
    should use STDOUT / :console.

### Added

  - Support for blacklisting controller actions with
    `Timber.Integrations.PhoenixInstrumentater`. This will suppress log lines
    from being written for any controller/action pair.

[Unreleased]: https://github.com/timberio/timber-elixir/compare/v2.5.5...HEAD
[2.5.5]: https://github.com/timberio/timber-elixir/compare/v2.5.4...v2.5.5
[2.5.4]: https://github.com/timberio/timber-elixir/compare/v2.5.3...v2.5.4
