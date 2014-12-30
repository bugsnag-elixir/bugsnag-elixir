defmodule Bugsnag.Mixfile do
  use Mix.Project

  def project do
    [app: :bugsnag,
     version: "1.0.0-dev",
     elixir: "~> 1.0.2",
     package: package,
     description: """
       An Elixir interface to the Bugsnag API
     """,
     deps: deps]
  end

  def package do
    [contributors: ["Jared Norman"],
     licenses: ["MIT"],
     links: [github: "https://github.com/jarednorman/bugsnag-elixir"]]
  end

  def application do
    [applications: []]
  end

  defp deps do
    [{:httpoison, "~> 0.5.0"},
     {:hackney, "~> 0.14.1"},
     {:exjsx, "~> 3.1.0"}]
  end
end
