defmodule Bugsnag.Mixfile do
  use Mix.Project

  def project do
    [app: :bugsnag,
     version: "1.3.2",
     elixir: "~> 1.0",
     package: package,
     description: """
       An Elixir interface to the Bugsnag API
     """,
     deps: deps]
  end

  def package do
    [contributors: ["Jared Norman", "Andrew Harvey"],
     maintainers: ["Andrew Harvey"],
     licenses: ["MIT"],
     links: %{github: "https://github.com/jarednorman/bugsnag-elixir"}]
  end

  def application do
    [applications: [:httpoison, :logger],
     mod: {Bugsnag, []}]
  end

  defp deps do
    [{:httpoison, "~> 0.6"},
     {:poison, "~> 1.5 or ~> 2.0"},

     {:meck, "~> 0.8.3", only: :test}]
  end
end
