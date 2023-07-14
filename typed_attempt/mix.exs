defmodule TypedAttempt.MixProject do
  use Mix.Project

  def project do
    [
      app: :typed_attempt,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_options: [warnings_as_errors: true],
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
      {:circe, "~> 0.2"},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false},
    ]
  end
end
