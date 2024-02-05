defmodule CiPipelineViz.MixProject do
  use Mix.Project

  def project do
    [
      app: :ci_pipeline_viz,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {CiPipelineViz.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "== 1.7.11"},
      {:phoenix_html, "== 4.0.0"},
      {:phoenix_live_reload, "== 1.4.1", only: :dev},
      {:phoenix_live_view, "== 0.20.3"},
      {:floki, "== 0.35.3", only: :test},
      {:phoenix_live_dashboard, "== 0.8.3"},
      {:esbuild, "== 0.8.1", runtime: Mix.env() == :dev},
      {:tailwind, "== 0.2.2", runtime: Mix.env() == :dev},
      {:bun, "== 1.0.0", runtime: Mix.env() == :dev},
      {:telemetry_metrics, "== 0.6.2"},
      {:telemetry_poller, "== 1.0.0"},
      {:jason, "== 1.4.1"},
      {:bandit, "== 1.1.3"},
      {:dotenv_parser, "== 2.0.0"},
      {:neuron, "== 5.1.0"},
      {:dialyxir, "== 1.4.3", only: [:dev, :test], runtime: false},
      {:tailwind_formatter, "== 0.4.0", only: [:dev, :test], runtime: false}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "assets.setup", "assets.build"],
      "assets.setup": [
        "tailwind.install --if-missing",
        "esbuild.install --if-missing",
        "bun.install --if-missing"
      ],
      "assets.build": ["tailwind default", "esbuild default"],
      "assets.deploy": ["tailwind default --minify", "esbuild default --minify", "phx.digest"]
    ]
  end
end
