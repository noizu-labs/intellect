defmodule Noizu.Intellect.MixProject do
  use Mix.Project

  def project do
    [
      app: :noizu_intellect,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [
        summary: [
          threshold: 0
        ]
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Noizu.Intellect.Application, []},
      extra_applications: [:logger, :runtime_tools, :noizu_labs_core, :noizu_labs_entities, :noizu_labs_open_ai]
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
      {:yaml_elixir, "~> 2.9.0"},
      {:phoenix, "~> 1.7.2"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.6"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 3.3"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.19.5"},
      #{:phoenix_live_view, github: "noizu/phoenix_live_view", branch: "0.18.18", override: true},
      {:earmark, "~> 1.4"},
      {:floki, ">= 0.30.0"},
      {:phoenix_live_dashboard, "~> 0.8"},
      {:esbuild, "~> 0.7", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2.0", runtime: Mix.env() == :dev},
      {:swoosh, "~> 1.3"},
      {:finch, "~> 0.15"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.5"},
      {:quantum, "~> 3.0"},
      {:bcrypt_elixir, "~> 2.0"},
      {:ueberauth, "~> 0.10.5"},
      {:guardian, "~> 2.3.1"},
      {:poison, "~> 3.1.0"},
      {:redix, "~> 1.1"},
      {:timex, "~> 3.7.9"},
      {:fast_yaml, "~> 1.0.36"},
      {:ex_fixer, github: "noizu/ex_fixer", branch: "master", only: [:dev, :test]},
      # Discord  https://blog.discordapp.com/scaling-elixir-f9b8e1e7c29b
      {:fastglobal, "~> 1.0"}, # https://github.com/discordapp/fastglobal
      {:semaphore, "~> 1.0"}, # https://github.com/discordapp/semaphore

      {:elixir_uuid, "~> 1.2"},
      {:junit_formatter, "~> 3.3", only: [:test]},

      # Internal - Dev
      {:noizu_weaviate, path: "elixir-framework/apps/elixir-weaviate"},
      {:noizu_github, path: "elixir-framework/apps/noizu_github"},
      {:noizu_labs_open_ai, path: "elixir-framework/apps/noizu_labs_open_ai"},
      {:noizu_labs_entities_ecto, path: "elixir-framework/apps/entities/ecto_entities"},
      {:noizu_labs_services, path: "elixir-framework/apps/noizu_labs_services"},

      # test
      {:mimic, "~> 1.0.0", only: :test},

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
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind default", "esbuild default"],
      "assets.deploy": ["tailwind default --minify", "esbuild default --minify", "phx.digest"]
    ]
  end
end
