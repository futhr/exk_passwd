defmodule ExkPasswd.MixProject do
  use Mix.Project

  @version "0.1.2"
  @source_url "https://github.com/futhr/exk_passwd"

  def project do
    [
      app: :exk_passwd,
      version: @version,
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),

      # Supress consolidate_protocols warnings in dev environment
      consolidate_protocols: Mix.env() != :dev,

      # Hex package
      description: description(),
      package: package(),

      # Documentation
      name: "ExkPasswd",
      source_url: @source_url,
      homepage_url: @source_url,
      docs: docs(),
      test_coverage: [tool: ExCoveralls, minimum_coverage: 95.0],
      preferred_cli_env: [
        check: :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.github": :test,
        "test.watch": :test
      ],
      dialyzer: [
        # Store PLT in priv to avoid rebuilding
        plt_core_path: "priv/plts",
        plt_file: {:no_warn, "priv/plts/exk_passwd.plt"},

        # Minimal warnings - only real type errors
        flags: [:error_handling, :unknown],

        # Add test dependencies for better coverage
        plt_add_apps: [:mix, :ex_unit]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto]
    ]
  end

  defp elixirc_paths(:test), do: ["lib"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Development
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:ex_check, "~> 0.16", only: [:dev], runtime: false},
      {:doctor, "~> 0.21", only: :dev, runtime: false},
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false},
      {:benchee, "~> 1.3", only: :dev, runtime: false},

      # Test
      {:excoveralls, "~> 0.18", only: :test},
      {:mix_test_watch, "~> 1.2", only: [:dev, :test], runtime: false},
      {:statistex, "~> 1.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      # Setup
      setup: ["deps.get", "deps.compile", "compile"],

      # Formatting
      format: ["format"],

      # Quality checks
      check: ["format --check-formatted", "credo --strict", "test"],
      "check.all": ["check", "dialyzer"],

      # Testing
      test: ["test --cover --stale"],
      "test.watch": ["test.watch --stale"],

      # Benchmarks
      bench: ["bench.all"],
      "bench.all": ["bench.password", "bench.dict", "bench.batch"],
      "bench.password": ["run bench/password_generation.exs"],
      "bench.dict": ["run bench/dictionary.exs"],
      "bench.batch": ["run bench/batch.exs"],

      # Documentation
      docs: ["docs --formatter html"],

      # Publishing
      "hex.publish": ["hex.build", "hex.publish", "tag"],
      tag: &tag_release/1
    ]
  end

  defp description do
    """
    Secure, memorable password generation using the XKPasswd method. Combines random
    words with numbers and symbols to create strong passwords that are easier to remember
    than random character strings. Features entropy analysis, batch generation, character
    substitutions, and custom dictionaries. Efficient with constant-time lookups. Zero runtime
    dependencies, uses only Elixir stdlib and :crypto.
    """
  end

  defp package do
    [
      files: ~w(
        lib
        priv
        docs
        .formatter.exs
        mix.exs
        README.md
        LICENSE.md
        CHANGELOG.md
        CLAUDE.md
        usage-rules.md
      ),
      maintainers: [
        "Michael Westbay <westbaystars@gmail.com>",
        "Tobias Bohwalli <hi@futhr.io>"
      ],
      licenses: ["BSD-2-Clause"],
      source_url: @source_url,
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md",
        "Issues" => "#{@source_url}/issues",
        "Original Perl" => "https://github.com/bbusschots/hsxkpasswd",
        "EFF Wordlist" => "https://www.eff.org/deeplinks/2016/07/new-wordlists-random-passphrases"
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      assets: %{"priv/static" => "assets"},
      extras: [
        "README.md": [title: "Overview"],
        "docs/SECURITY.md": [title: "Security"],
        "docs/LIVEBOOK_SETUP.md": [title: "Livebook & Benchmarking"],
        "notebooks/quickstart.livemd": [title: "Quick Start"],
        "notebooks/advanced.livemd": [title: "Advanced Usage"],
        "notebooks/security.livemd": [title: "Security Analysis"],
        "notebooks/benchmarks.livemd": [title: "Benchmarks"],
        "notebooks/i18n_chinese.livemd": [title: "Chinese i18n (Pinyin)"],
        "notebooks/i18n_japanese.livemd": [title: "Japanese i18n (Romaji)"],
        "notebooks/contributing.livemd": [title: "Contributing Guide (Interactive)"],
        "CHANGELOG.md": [title: "Changelog"],
        "docs/CONTRIBUTING.md": [title: "Contributing"],
        "LICENSE.md": [title: "License"]
      ],
      groups_for_modules: [
        "Core API": [
          ExkPasswd
        ],
        Configuration: [
          ExkPasswd.Config,
          ExkPasswd.Config.Presets,
          ExkPasswd.Config.Schema,
          ExkPasswd.Validator
        ],
        "Password Generation": [
          ExkPasswd.Password,
          ExkPasswd.Batch,
          ExkPasswd.Token,
          ExkPasswd.Buffer
        ],
        Transforms: [
          ExkPasswd.Transform,
          ExkPasswd.Transform.CaseTransform,
          ExkPasswd.Transform.Substitution
        ],
        "Security Analysis": [
          ExkPasswd.Entropy,
          ExkPasswd.Strength
        ],
        Utilities: [
          ExkPasswd.Dictionary,
          ExkPasswd.Random
        ]
      ],
      groups_for_extras: [
        "Getting Started": ~r/README|docs\/SECURITY|docs\/LIVEBOOK_SETUP/,
        "Interactive Tutorials": ~r/notebooks\//,
        Reference: ~r/CHANGELOG|docs\/CONTRIBUTING|LICENSE/
      ],
      source_ref: "v#{@version}",
      source_url: @source_url,
      formatters: ["html"]
    ]
  end

  defp tag_release(_) do
    Mix.shell().info("Tagging release as v#{@version}")
    System.cmd("git", ["tag", "-a", "v#{@version}", "-m", "Release v#{@version}"])
    System.cmd("git", ["push", "--tags"])
  end
end
