defmodule EvEffVsTransformers.MixProject do
  use Mix.Project

  def project do
    [
      app: :ev_eff_vs_transformers,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ev_eff, path: "../ev_eff"},
      {:transformers, path: "../../transformers.ex"},
      {:computation_expression, path: "../../computation_expression.ex"},
      {:hallux, "~> 1.2"},
      {:benchee, "~> 1.0", only: :dev},
      {:beam_file, "~> 0.6.2", only: :dev},
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
