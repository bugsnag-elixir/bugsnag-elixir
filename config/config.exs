use Mix.Config

if Mix.env == :test, do: config :bugsnag, :api_key, "FAKEKEY"
