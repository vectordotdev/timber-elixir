# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

  - The `Timber.LocalContext` now manages setting and updating the Timber context
    maintained in the Elixir Logger metadata. This replaces the `Timber.CurrentContext`
    module. `Timber.LocalContext.get/0` should be used where
    `Timber.CurrentContext.load/0` was used before, and `Timber.LocalContext.put/1`
    should be used where `Timber.CurrentContext.save/1` was used.

### Deprecated

  - `Timber.CurrentContext` has been deprecated in favor of `Timber.LocalContext`;
    the new name better reflects the purpose of the module. Use of
    `Timber.CurrentContext` will still be supported for the lifetime of v2

## [2.6.1] - 2017-10-02

### Fixed

  - Fixed an error where `Timber.Integrations.PhoenixInstrumenter` would fail
    on versions of Phoenix prior to 1.3 that do not pass a `:conn` key with the
    `phoenix_controller_render/3` `:start` event.

  - Fixed `Timber.Integrations.PhoenixInstrumenter` did not define a
    fall-through for `phoenix_controller_render/3` during the `:start` event for
    when the third-parameter is in a different format than expected.

  - Fixed `Timber.Integrations.PhoenixInstrumenter` did not define a
    fall-through when the instrumentation system sends a default state value for
    the `:stop` event on `phoenix_controller_render/3`.

## [2.6.0] - 2017-09-28

### Changed

  - Logger backends now conform to the `:gen_event` behaviour rather than calling
    the `GenEvent.__using__/1` macro which is deprecated in Elixir 1.5.0 and
    above. The change is backwards compatible since `:gen_event` is provided by
    all supported versions of Erlang.

## [2.5.6] - 2017-09-28

### Fixed

  - Fixed an error where `Timber.Integrations.PhoenixInstrumenter` would cause
    an error during blacklist checks if the blacklist had not been set up.

  - Fixed an error where `Timber.Integrations.PhoenixInstrumenter` would fail on render
    events for `conn` structs that did not have a controller or action set. For
    example, when a `conn` did not match listed routes, a `404.html` template
    would be rendered that did not have a controller or action. The render event
    would still be triggered though.

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
    `Timber.Integrations.PhoenixInstrumenter`. This will suppress log lines
    from being written for any controller/action pair.

[Unreleased]: https://github.com/timberio/timber-elixir/compare/v2.6.1...HEAD
[2.6.1]: https://github.com/timberio/timber-elixir/compare/v2.6.0...v2.6.1
[2.6.0]: https://github.com/timberio/timber-elixir/compare/v2.5.6...v2.6.0
[2.5.6]: https://github.com/timberio/timber-elixir/compare/v2.5.5...v2.5.6
[2.5.5]: https://github.com/timberio/timber-elixir/compare/v2.5.4...v2.5.5
[2.5.4]: https://github.com/timberio/timber-elixir/compare/v2.5.3...v2.5.4
