# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.5.4] - 2017-09-18

### Fixed

  - Fixed a bug within the installer where HTTP log delivery was being used on platforms that
    should use STDOUT / :console.

### Added

  - Support for blacklisting controller actions with
    `Timber.Integrations.PhoenixInstrumentater`. This will suppress log lines
    from being written for any controller/action pair.

[Unreleased]: https://github.com/timberio/timber-elixir/compare/v2.5.4...HEAD
[2.5.4]: https://github.com/timberio/timber-elixir/compare/v2.5.3...v2.5.4
