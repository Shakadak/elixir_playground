defmodule FiniteDomain.MixProject do
  use Mix.Project

  def project do
    [
      app: :finite_domain,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript(),
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
      {:computation_expression, path: "../../computation_expression", override: true},
      {:transformers, path: "../../transformers.ex"},

      ### DEV
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:beam_file, ">= 0.0.0", only: :dev, runtime: false},
    ]
  end

  defp escript do
    [
      main_module: Example.Cli,
    ]
  end
end
