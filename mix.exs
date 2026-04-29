defmodule Azav.CredoChecks.MixProject do
  use Mix.Project

  @source_url "https://github.com/paperpilots/credo_checks"

  def project do
    [
      app: :azav_credo_checks,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: description(),
      name: "AZAV Pilot CredoChecks",
      source_url: @source_url
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
      {:credo, "~> 1.7"}
    ]
  end

  defp description() do
    "A collection of credo checks used by AZAV Pilot to spot common errors and code quality issues."
  end

  def package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end
end
