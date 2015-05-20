# Bugsnag Elixir

Capture exceptions and send them to the [Bugsnag](http://bugsnag.com) API!

## Installation

```elixir
# Add it to your deps in your projects mix.exs
defp deps do
  [{:bugsnag, "~> 1.0.0"}]
end

# Open up your config/config.exs (or appropriate project config)
config :bugsnag, api_key: "bbf085fc54ff99498ebd18ab49a832dd"
```

## Usage

```elixir

# Report an exception.
try do
  :foo = :bar
rescue
  exception -> Bugsnag.report(exception)
end
```
