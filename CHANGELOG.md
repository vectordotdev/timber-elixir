# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.8.2] - 2018-07-01

### Changed

  - Allow `~> 2.0` for the `:msgpax` dependency.

## [2.8.1] - 2018-06-07

### Added

  - Add support for inline context via the `:context` `Logger` metadata key.
  - Add `Timber.remove_context_key` for removing an individual keys off of context structures.

### Changed

  - Relax the `:plug` dependency to allow for more plug versions.

## [2.8.0] - 2018-04-16

### Added

  - `Timber.Integrations.ErrorLogger` allows you to include a new OTP
    `:error\_logger` handler to better maintain the structure of errors and
    stacktraces. It also collapses many cases of multi-line logs into a single
    line.

### Fixed

  - Fixed Logger metadata to use the pid from the Logger event and fall back
    to `self()`.

  - Fix an issue with the regular expression that detects the Router during
    installation.

  - Fix an issue with being able to skip files during installation when multiple
    files match.

## [2.7.0] - 2018-03-22

### Added

  - `Timber.add_context/2` now allows you to set context either locally or globally;
    `Timber.add_context/1` will default to storing the context locally (consistent
    with previous versions of the library)
  - The `Timber.LocalContext` now manages setting and updating the Timber context
    maintained in the Elixir Logger metadata. This replaces the `Timber.CurrentContext`
    module. `Timber.LocalContext.get/0` should be used where
    `Timber.CurrentContext.load/0` was used before, and `Timber.LocalContext.put/1`
    should be used where `Timber.CurrentContext.save/1` was used.

### Changed

  - `Timber.LogEntry.new/4` will fetch the global context and merge it into the
    local metadata context. The local context will override the global context
    based on the rules for `Timber.Context.merge/2`
  - Phoenix Channels integration will now accept _any_ channel message payload.
    (Previously, non-map types were dropped and replaced with an empty map.)

### Deprecated

  - `Timber.CurrentContext` has been deprecated in favor of `Timber.LocalContext`;
    the new name better reflects the purpose of the module. Use of
    `Timber.CurrentContext` will still be supported for the lifetime of v2

### Fixed

  - Phoenix Channels integration with Phoneix 1.3+ will no longer fail if the
    payload of a channel message is a list

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

[Unreleased]: https://github.com/timberio/timber-elixir/compare/v2.8.1...HEAD
[2.8.1]: https://github.com/timberio/timber-elixir/compare/v2.8.0...v2.8.1
[2.8.0]: https://github.com/timberio/timber-elixir/compare/v2.7.0...v2.8.0
[2.7.0]: https://github.com/timberio/timber-elixir/compare/v2.6.1...v2.7.0
[2.6.1]: https://github.com/timberio/timber-elixir/compare/v2.6.0...v2.6.1
[2.6.0]: https://github.com/timberio/timber-elixir/compare/v2.5.6...v2.6.0
[2.5.6]: https://github.com/timberio/timber-elixir/compare/v2.5.5...v2.5.6
[2.5.5]: https://github.com/timberio/timber-elixir/compare/v2.5.4...v2.5.5
[2.5.4]: https://github.com/timberio/timber-elixir/compare/v2.5.3...v2.5.4
