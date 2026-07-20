defmodule ActualisStock.MixProject do
  use Mix.Project

  def project do
    [
      app: :actualis_stock,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_environment), do: ["lib"]

  defp deps do
    [
      {:actualis_core, in_umbrella: true},
      {:ecto, "~> 3.13"}
    ]
  end

  defp aliases do
    [setup: ["deps.get"]]
  end
end
