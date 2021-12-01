# Bugsnag Elixir

[![Elixir CI](https://github.com/bugsnag-elixir/bugsnag-elixir/workflows/Elixir%20CI/badge.svg)](https://github.com/bugsnag-elixir/bugsnag-elixir/actions)
[![Bugsnag Version](https://img.shields.io/hexpm/v/bugsnag.svg)](https://hex.pm/packages/bugsnag)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/bugsnag/)
[![Total Download](https://img.shields.io/hexpm/dt/bugsnag.svg)](https://hex.pm/packages/bugsnag)
[![License](https://img.shields.io/hexpm/l/bugsnag.svg)](https://github.com/bugsnag-elixir/bugsnag/blob/master/LICENSE)
[![Last Updated](https://img.shields.io/github/last-commit/bugsnag-elixir/bugsnag-elixir.svg)](https://github.com/bugsnag-elixir/bugsnag-elixir/commits/master)


Capture exceptions and send them to the [Bugsnag](https://www.bugsnag.com/) API!

🔗 See also: [Plugsnag], to snag exceptions in your Phoenix application.

[Plugsnag]: https://github.com/bugsnag-elixir/plugsnag

<!-- MarkdownTOC autolink="true" bracket="round" levels="1,2,3" -->

- [Bugsnag Elixir](#bugsnag-elixir)
  - [Installation](#installation)
  - [Configuration](#configuration)
    - [Example](#example)
    - [`api_key`](#api_key)
    - [`release_stage`](#release_stage)
    - [`notify_release_stages`](#notify_release_stages)
    - [`hostname`](#hostname)
    - [`app_type`](#app_type)
    - [`app_version`](#app_version)
    - [`sanitizer`](#sanitizer)
    - [`in_project`](#in_project)
      - [String Matching](#string-matching)
      - [Regex Matching](#regex-matching)
      - [Custom Function](#custom-function)
    - [`endpoint_url`](#endpoint_url)
    - [`use_logger`](#use_logger)
    - [`exception_filter`](#exception_filter)
    - [`json_library`](#json_library)
    - [`http_client`](#http_client)
  - [Usage](#usage)
    - [Manual Reporting](#manual-reporting)
    - [Reporting Options](#reporting-options)
  - [License](#license)

<!-- /MarkdownTOC -->


## Installation

```elixir
# mix.exs
defp deps do
  [
    {:bugsnag, "~> 3.0.1"},
    # pick ONE of these JSON encoding libraries:
    {:jason, "~> 1.0"},
    {:poison, "~> 4.0"}
    # add your http client of choice
    # or use httpoison for the default adapter:
    {:httpoison, "~> 1.0"},
  ]
end
```

```elixir
# config/config.exs
config :bugsnag,
  api_key: "0123456789abcdef0123456789abcdef"
```

The `:bugsnag` application must be started to report errors — this should be
done automatically by [application inference][1], as long as the `application`
function in your `mix.exs` does not contain an `applications` key. If it does,
you'll want to add `:bugsnag` to the list of applications.

[1]: https://sergiotapia.me/application-inference-in-elixir-1-4-ae9e43e90301

By default, the application adds an Erlang `:error_logger` handler on startup
that will report most process crashes automatically. If you only want to report
errors manually, this can be configured via the `use_logger` option (see below).


## Configuration

Although errors will be reported even if you only set an API key, some Bugsnag
features (like release stage and app version tagging, or marking stack frames as
"in-project") require additional configuration.

All configuration options support `{:system, "ENV_VAR"}` tuples for retrieving
values from environment variables at application startup. You can also specify
a default value using `{:system, "ENV_VAR", "default_value"}`.

### Example

This config uses all available features. It assumes your project is a single
application whose code is in `lib/my_app_name`, and you have an environment
variable `MY_APP_ENV` set to values like `"staging"` or `"production"` depending
on the runtime environment.

```elixir
# config/config.exs
config :bugsnag,
  api_key: "0123456789abcdef0123456789abcdef",
  app_type: "elixir",
  app_version: Mix.Project.config[:version],
  endpoint_url: "https://self-hosted-bugsnag.myapp",
  hostname: {:system, "HOST", "unknown"},
  http_client: MyApp.BugsnagHTTPAdapter,
  in_project: "lib/my_app_name",
  json_library: Jason,
  notify_release_stages: ["staging", "production"],
  release_stage: {:system, "MY_APP_ENV", "production"},
  sanitizer: {MyModule, :my_function},
  use_logger: true
```

See below for explanations of each option, including some options not used here.

### `api_key`

**Default:** `nil`

Must be set to report errors.

### `release_stage`

**Default:** `"production"`

Sets the default "release stage" for reported errors. If set to a value that is
not included in `notify_release_stages`, all reports will be silently discarded.

### `notify_release_stages`

**Default:** `["production"]`

If the configured `release_stage` is not in this list, all error reports are
silently discarded. This allows ignoring errors in release stages you don't want
to clutter your Bugsnag dashboard, e.g. development or test.

To accommodate configuration via environment variables, if set to a string, the
string will be split on commas (`,`).

### `hostname`

**Default:** `"unknown"`

Sets the default hostname for reported errors.

### `app_type`

**Default:** `"elixir"`

Sets the default application type for reported errors.

### `app_version`

**Default:** `nil`

Sets the default application version for reported errors.

### `sanitizer`

**Default:** `nil`

A function to be applied over contents of stack traces.

Example

```elixir
defmodule MyModule do
  def my_func(word) do
    Regex.replace(~r/fail/, word, "pass")
  end
end

config :bugsnag, sanitizer: {MyModule, :my_func}
```

```
raise "123fail123"
```

Produces the failure message
```elixir
123pass123
```

If a sanitizer function throws an exception while running, it will log out a warning and return the string `[CENSORED DUE TO SANITIZER EXCEPTION]`

### `in_project`

**Default:** `nil`

When reporting the stack trace of an exception, Bugsnag allows marking each
stack frame as being "in your project" or not. This enables grouping errors by
the deepest stack frame that is in your project. Unfortunately it's hard to do
this automatically in Elixir, because file paths in stack traces are relative to
the application the file is part of (i.e. all start with `lib/some_app/...`).
Since we don't know which apps are "yours", this option must be set to enable
marking stack frames as in-project.

This option can be set in several ways:

#### String Matching

```elixir
config :bugsnag, in_project: "lib/my_app_name"
```

If a stack frame's file path contains the string, it will be marked in-project.

#### Regex Matching

```elixir
config :bugsnag, in_project: ~r(my_app_name|my_other_app)
```

If a stack frame's file path matches the regex, it will be marked in-project.

#### Custom Function

```elixir
config :bugsnag, in_project: fn({module, function, arguments, file_path}) ->
  module in [SomeMod, OtherMod] or file_path =~ ~r(^lib/my_project)
end
```

If the function returns a truthy value when called with the stack frame as an
argument, the stack frame will be marked in-project. You can also specify a
function as a `{Module, :function, [extra_args]}` tuple (the stack frame tuple
will be prepended as the first argument to the function).

### `endpoint_url`

**Default:** `"https://notify.bugsnag.com"`

Allows sending reports to a different URL (e.g. if using Bugsnag On-premise).

### `use_logger`

**Default:** `true`

Controls whether the default Erlang `:error_logger` handler is added on
application startup. This will automatically report most process crashes.

### `exception_filter`

**Default:** `nil`

Optional module that allows filtering of log messages. For example
```Elixir
defmodule MyApp.ExceptionFilter do
  def should_notify({{%{plug_status: resp_status},_},_}, _stacktrace) when is_integer(resp_status) do
    #structure used by cowboy 2.0
    resp_status < 400 or resp_status >= 500
  end
  def should_notify(_e, _s), do: true
end
```

### `json_library`

**Default:** `Jason`

The JSON encoding library.

### `http_client`

**Default** `Bugsnag.HTTPClient.Adapters.HTTPoison`

An adapter implementing the `Bugsnag.HTTPClient` behaviour.

## Usage

In the default configuration, unhandled exceptions that crash a process will be
automatically reported to Bugsnag. If you want to report a rescued exception, or
have `use_logger` disabled, you can send reports manually.

### Manual Reporting

Use `Bugsnag.report` to report an exception:

```elixir
try do
  raise "heck"
rescue exception ->
  Bugsnag.report(exception)
end
```

This reports the exception in a separate process so your application code will
not be held up. However, this means reporting could fail silently. If you want
to wait on the report in your own process (and potentially crash, if reporting
fails), use `Bugsnag.sync_report`:

```elixir
try do
  raise "heck"
rescue exception ->
  :ok = Bugsnag.sync_report(exception)
end
```

### Reporting Options

Both `report` and `sync_report` accept an optional second argument to add more
data to the report or override the application configuration:

```elixir
try do
  raise "heck"
rescue exception ->
  Bugsnag.report(exception, severity: "warning", context: "worker")
end
```

The following options override their corresponding app config values:

* `api_key`
* `release_stage`
* `notify_release_stages`
* `hostname`
* `app_type`
* `app_version`

The following options allow adding more data to the report:

* `severity` — Sets the severity of the report (`error`, `warning`, or `info`)
* `context` — Sets the "context" string (e.g. `controller#action` in Phoenix)
* `user` — Map of information about the user who encountered the error:
  * `id` - String ID for the user
  * `name` - Full name of the user
  * `email` - Email address of the user
* `os_version` — Sets the reported OS version of the error
* `stacktrace` — Allows passing in a stack trace, e.g. from `__STACKTRACE__`
* `metadata` - Map of arbitrary metadata to include with the report
* `error_class` - Allows passing in the error type instead of inferring from the error struct

[See the Bugsnag docs][2] for more information on these fields.

[2]: https://bugsnagerrorreportingapi.docs.apiary.io/#reference/0/notify/send-error-reports

## License

This source code is licensed under the MIT license found in the LICENSE file.
Copyright (C) 2014-present Jared Norman
