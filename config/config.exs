use Mix.Config

case Mix.env do
  :dev -> config :bugsnag, api_key: System.get_env("BUGSNAG_API_KEY")
  :test -> config :bugsnag, api_key: "LOLIGOTCHA"
end
