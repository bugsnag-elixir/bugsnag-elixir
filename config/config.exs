use Mix.Config
config :bugsnag, api_key: System.get_env("BUGSNAG_API_KEY")
