# Bugsnag Elixir [![Build Status](https://travis-ci.org/jarednorman/bugsnag-elixir.svg?branch=master)](https://travis-ci.org/jarednorman/bugsnag-elixir)

Capture exceptions and send them to the [Bugsnag](http://bugsnag.com) API!

## Installation

```elixir
# Add it to your deps in your projects mix.exs
defp deps do
  [{:bugsnag, "~> 1.3.2"}]
end

# Now, list the :bugsnag application as your application dependency:
def application do
  [applications: [:bugsnag]]
end

# Open up your config/config.exs (or appropriate project config)
config :bugsnag, api_key: "bbf085fc54ff99498ebd18ab49a832dd"

# Set the release stage in your environment configs (e.g. config/prod.exs)
config :bugsnag, release_stage: "prod"

# Set `use_logger: true` to report all uncaught exceptions (using Erlang SASL)
config :bugsnag, use_logger: true
```

## Usage

### Configuration

You can use environment variables in order to set up all options. You can set default variable names, and don't touch config files, eg:

- `BUGSNAG_API_KEY`
- `BUGSNAG_USE_LOGGER`
- `BUGSNAG_RELEASE_STAGE`

Or you can define from which env vars it should be loaded, eg:

```elixir
config :bugsnag, :api_key,        {:system, "YOUR_ENV_VAR" [, optional_default]}
config :bugsnag, :release_stage,  {:system, "YOUR_ENV_VAR" [, optional_default]}
config :bugsnag, :ues_logger,     {:system, "YOUR_ENV_VAR" [, optional_default]}
```

Ofcourse you can use regular values as in Installation guide.

### Manual reporting

```elixir
# Report an exception.
try do
  :foo = :bar
rescue
  exception -> Bugsnag.report(exception)
end
```

### Options

These are optional fields to fill the bugsnag report with more information, depending on your specific usage scenario.
They can be passed into the `Bugsnag.report/2` function like so:

```elixir
# ...an exception occured
  Bugsnag.report(exception, severity: "warn", user: %{name: "Jane Doe"})
```

- `api_key` - Allows overriding any configured api key manually
- `stacktrace` - Allows explicitly passing in a stacktrace used to generate the stacktrace object that is sent to bugsnag
- `severity` - Sets the severity explicitly to "error", "warning" or "info"
- `release_stage` - Explicitly sets an arbitrary release stage e.g. "development", "test" or "production"
- `context` - Allows passing in context information, like e.g. the name of the file the crash occured in
- `user` - Allows passing in user information, needs to be a map with one or more of the following fields (which are then searchable):
  - `id` - Any binary identifier for the user
  - `name` - Full name of the user
  - `email` - Full email of the user
- `os_version` and `hostname` - Will be aggregated within Bugsnag's `device` field and can be used as a filter
- `metadata` - Arbitrary metadata (See [Bugsnag docs](https://docs.bugsnag.com/api/error-reporting/#json-payload) for more information)

### Logger

Set the `use_logger` option to true in your application's `config.exs`.
So long as `:bugsnag` is started, any [SASL](http://www.erlang.org/doc/apps/sasl/error_logging.html)
compliant processes that crash will send an error report to the `Bugsnag.Logger`.
The logger will take care of sending the error to Bugsnag.

