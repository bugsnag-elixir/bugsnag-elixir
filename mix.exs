defmodule Bugsnag.Mixfile do
  use Mix.Project

  def project do
    [
      app: :bugsnag,
      version: "2.0.0",
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      description: "An Elixir interface to the Bugsnag API.",
      deps: deps()
    ]
  end

  def package do
    [
      contributors: ["Jared Norman", "Andrew Harvey", "Alex Grant", "Coburn Berry"],
      maintainers: ["Coburn Berry"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/bugsnag-elixir/bugsnag-elixir"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_), do: ["lib", "web"]

  def application do
    [applications: [:httpoison, :logger], mod: {Bugsnag, []}]
  end

  defp deps do
    [
      {:httpoison, "~> 0.13 or ~> 1.0"},
      {:jason, "~> 1.0", optional: true},
      {:poison, ">= 1.5.0", optional: true},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:meck, "~> 0.9.0", only: :test}
    ]
  end
end
