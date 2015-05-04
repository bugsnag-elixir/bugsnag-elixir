defmodule Bugsnag.Mixfile do
  use Mix.Project

  def project do
    [app: :bugsnag,
     version: "1.0.1",
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
     links: %{github: "https://github.com/jarednorman/bugsnag-elixir"}]
  end

  def application do
    [applications: []]
  end

  defp deps do
    [{:httpoison, "~> 0.6"},
     {:poison, "~> 1.3"}]
  end
end
