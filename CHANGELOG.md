# Changelog

## Unreleased

## 2.1.1

### Added
- Reuse file/line information from previous frame for UndefinedFunctionError [#88](https://github.com/bugsnag-elixir/bugsnag-elixir/pull/88)

### Fixed
- Change back return type of `Bugsnag.report/2` to `{:ok, pid}` (changed to `:ok` in 2.1.0)

## 2.1.0

### Fixed
- Add support for poison 4.0 by loosening version requirement [#102](https://github.com/bugsnag-elixir/bugsnag-elixir/pull/102)
- Removed warning on Elixir 1.10 [#92](https://github.com/bugsnag-elixir/bugsnag-elixir/pull/92)
- Removed deprecated Supervisor.Spec
- Moved to using `extra_applications`

### Removed
- Removed Bugsnag.json_library/0 [#101](https://github.com/bugsnag-elixir/bugsnag-elixir/pull/101)
- Removed Bugsnag.should_notify/2
