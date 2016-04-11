defmodule Bugsnag.Mixfile do
  use Mix.Project

  def project do
    [app: :bugsnag,
     version: "1.2.0",
     elixir: "~> 1.0",
     package: package,
     description: """
       An Elixir interface to the Bugsnag API
     """,
     deps: deps]
  end

  def package do
    [contributors: ["Jared Norman", "Rafael Albuquerque"],
     licenses: ["MIT"],
     links: %{github: "https://github.com/Talkdesk/bugsnag-elixir"}]
  end

  def application do
    [applications: [:httpoison]]
  end

  defp deps do
    [{:httpoison, "~> 0.6"},
     {:poison, "~> 1.3"}]
  end
end
