# Changelog

## Unreleased

## 3.0.1

### Fixed

- Fix handling of stacktrace pattern for Erlang 24 [#113](https://github.com/bugsnag-elixir/bugsnag-elixir/pull/113)
- Remove deprecated system stacktrace warnings in tests [#112](https://github.com/bugsnag-elixir/bugsnag-elixir/pull/112)

### Extra 
- Add Erlang 24 to CI [#114](https://github.com/bugsnag-elixir/bugsnag-elixir/pull/114)

## 3.0.0

The most notable change in this release is the inclusion of an HTTP Client adapter and the possibility of adding your own client. By doing this, `httpoison` is now an optional dependency and must be included in the dependency list in order to use the default adapter.

### BREAKING CHANGES

`httpoison` is now an `optional` dependency. If you want to use the default `HTTPoison` adapter, add `httpoison` as a dependency to your app:
```elixir
  # mix.exs
  defp deps do
    [
      {:bugsnag, "~> 3.0.0"},
      {:httpoison, "~> 1.0"},
      ...
    ]
  end
```
If you want to use other http client already in your project. Create a new adapter implementing the `Bugsnag.HTTPClient` behaviour, and configure Bugsnag to use it. eg:
```elixir
# config/config.exs
config :bugsnag,
  ...,
  http_client: MyApp.BugsnagHTTPAdapterUsingMyPreferredLib
```

### Removed

- Removed support for elixir < 1.8

### Added
- Add `Bugsnag.HTTPClient` and default `Bugsnag.HTTPClient.Adapter.HTTPoison` adapter, configurable via `http_client` application config
- Add option to set error class instead of inferring from the exception [#108](https://github.com/bugsnag-elixir/bugsnag-elixir/pull/108)

### Fixed / Maintenance

- Ensure tasks under Bugsnag.TaskSupervisor don't spill into other tests [#106](https://github.com/bugsnag-elixir/bugsnag-elixir/pull/106)
- bump dependencies: jason, mox, ex_docs

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
