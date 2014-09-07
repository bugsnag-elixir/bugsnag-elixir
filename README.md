Bugsnag Elixir
==============

Capture exceptions and send them to the [Bugsnag](http://bugsnag.com) API! All
it needs is your API key (see example configuration in config/config.exs) and
then reporting errors is as simple as:

```elixir
# Warm up the engine
Bugsnag.start

try do
  :foo = :bar
rescue
  exception -> Bugsnag.report(exception)
end
```

## Roadmap

In the future it will be able report optional information that Bugsnag accepts
like session, user and context information. I'll be adding those features as I
build out [an integration](https://github.com/jarednorman/plugsnag) for
[Plug](https://github.com/elixir-lang/plug)/[Phoenix](https://github.com/phoenixframework/phoenix).
