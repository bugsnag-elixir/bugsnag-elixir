# Changelog

## Unreleased

### Warning

`httpoison` is now an `optional` dependency. If you want to use the default `HTTPoison` adapter, add `httpoison` as a dependency to your app:
```elixir
  # mix.exs
  defp deps do
    [
      {:bugsnag, "~> 2.1.0"},
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


## Added
- Add `Bugsnag.HTTPClient` and default `Bugsnag.HTTPClient.Adapter.HTTPoison` adapter, configurable via `http_client` application config

## 2.1.0

### Fixed
- Add support for poison 4.0 by loosening version requirement [#102](https://github.com/bugsnag-elixir/bugsnag-elixir/pull/102)
- Removed warning on Elixir 1.10 [#92](https://github.com/bugsnag-elixir/bugsnag-elixir/pull/92)
- Removed deprecated Supervisor.Spec
- Moved to using `extra_applications`

### Removed
- Removed Bugsnag.json_library/0 [#101](https://github.com/bugsnag-elixir/bugsnag-elixir/pull/101)
- Removed Bugsnag.should_notify/2
