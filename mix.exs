defmodule Bugsnag.Mixfile do
  use Mix.Project

  def project do
    [app: :bugsnag,
     version: "1.3.0",
     elixir: "~> 1.3",
     package: package,
     description: """
       An Elixir interface to the Bugsnag API
     """,
     deps: deps]
  end

  def package do
    [contributors: ["Jared Norman"],
     licenses: ["MIT"],
     links: %{github: "https://github.com/jarednorman/bugsnag-elixir"}]
  end

  def application do
    [applications: [:httpoison, :logger]]
  end

  defp deps do
    [{:httpoison, "~> 0.8.2"},
     {:poison, "~> 2.2"},
     {:meck, "~> 0.8.3", only: :test}]
  end
end
