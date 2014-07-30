Bugsnag Elixir
==============

Capture exceptions and send them to the [Bugsnag](http://bugsnag.com) API! All
it needs is your API key (see example configuration in config/config.exs) and
then reporting errors is as simple as:

```elixir
try do
  :foo = :bar
catch
  _kind, error -> Bugsnag.crash(error)
end
```

You probably need to add `:httpoison` to your applications list too.

## Roadmap

In the future it will be able report optional information that Bugsnag accepts
like session, user and context information. I'll be adding those features as I
build out [an integration](https://github.com/jarednorman/plugsnag) for
[Plug](https://github.com/elixir-lang/plug)/[Phoenix](https://github.com/phoenixframework/phoenix).
