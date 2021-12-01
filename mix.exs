defmodule Bugsnag.Mixfile do
  use Mix.Project

  @source_url "https://github.com/bugsnag-elixir/bugsnag-elixir"
  @version "3.0.1"

  def project do
    [
      app: :bugsnag,
      version: @version,
      elixir: "~> 1.8",
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      description: "An Elixir interface to the Bugsnag API.",
      deps: deps(),
      docs: docs()
    ]
  end

  def package do
    [
      contributors: ["Jared Norman", "Andrew Harvey", "Alex Grant", "Coburn Berry"],
      maintainers: ["Guilherme de Maio"],
      licenses: ["MIT"],
      links: %{
        Changelog: @source_url <> "/blob/master/CHANGELOG.md",
        GitHub: @source_url
      }
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_), do: ["lib", "web"]

  def application do
    [
      mod: {Bugsnag, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:httpoison, ">= 0.13.0", optional: true},
      {:jason, "~> 1.0", optional: true},
      {:poison, ">= 1.5.0", optional: true},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:mox, "~> 1.0", only: :test}
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v" <> @version,
      source_url: @source_url,
      extras: ["README.md", "CHANGELOG.md"]
    ]
  end
end
