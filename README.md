### This project is looking for a maintainer. As much as I love the language, ecosystem, community around Elixir, I'm not currently lucky enough to be doing any serious work in the language. If someone would like to take some responsibility for the project I would hugely appreciate it.

# Bugsnag Elixir

Capture exceptions and send them to the [Bugsnag](http://bugsnag.com) API!

## Installation

```elixir
# Add it to your deps in your projects mix.exs
defp deps do
  [{:bugsnag, "~> 1.0.0"}]
end

# Now, list the :bugsnag application as your application dependency:
def application do
  [applications: [:bugsnag]]
end

# Open up your config/config.exs (or appropriate project config)
config :bugsnag, api_key: "bbf085fc54ff99498ebd18ab49a832dd"

# Set the release stage in your environment configs (e.g. config/prod.exs)
config :bugsnag, release_stage: "prod"
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
