defmodule Bugsnag.Mixfile do
  use Mix.Project

  def project do
    [ app: :bugsnag,
      version: "0.0.1",
      elixir: "~> 0.14.3",
      package: package,
      description: """
        An Elixir interface to the Bugsnag API
      """,
     deps: deps ]
  end

  def package do
    [ contributors: [ "Jared Norman" ],
      licenses: [ "MIT" ],
      links: [ github: "https://github.com/jarednorman/bugsnag-elixir" ] ]
  end

  def application do
    [ applications: [] ]
  end

  defp deps do
    [ { :httpoison, "~> 0.3.0" },
      { :hackney, "~> 0.13.0", github: "benoitc/hackney" },
      { :jsex, "~> 2.0.0" } ]
  end
end
