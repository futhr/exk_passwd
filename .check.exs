[
  ## Don't run tools concurrently
  parallel: false,

  ## Don't print summary
  skipped: true,

  ## Tool order
  tools: [
    ## Enable by default
    {:compiler, true},
    {:formatter, true},
    {:credo, true},
    {:test, true},
    {:hex_audit, true},   # Security: check for vulnerable dependencies
    {:mix_audit, true},   # Security: check for known vulnerabilities
    {:dialyzer, false},   # Disabled by default as it's slow
    {:doctor, false},     # Disabled by default, enable when needed
    {:ex_doc, false},     # Only run when generating docs
    {:sobelow, false},    # Security check - enable if Phoenix app

    ## Custom checks
    {:test_coverage, false}  # Run with coverage reporting
  ],

  ## Configure tools
  config: [
    ## Compiler
    compiler: [
      command: "mix compile --warnings-as-errors",
      env: %{},
      cd: nil,
      require_files: ["mix.exs"]
    ],

    ## Formatter
    formatter: [
      command: "mix format --check-formatted",
      env: %{},
      cd: nil,
      require_files: [".formatter.exs"]
    ],

    ## Credo
    credo: [
      command: "mix credo --strict",
      env: %{},
      cd: nil,
      require_files: [".credo.exs"]
    ],

    ## Test
    test: [
      command: "MIX_ENV=test mix test",
      env: %{},
      cd: nil,
      require_files: ["mix.exs"]
    ],

    ## Dialyzer
    dialyzer: [
      command: "mix dialyzer",
      env: %{},
      cd: nil,
      require_files: ["mix.exs"],
      detect: [{:file, "dialyzer"}]
    ],

    ## Doctor
    doctor: [
      command: "mix doctor",
      env: %{},
      cd: nil,
      require_files: ["mix.exs"],
      detect: [{:package, :doctor}]
    ],

    ## ExDoc
    ex_doc: [
      command: "mix docs",
      env: %{},
      cd: nil,
      require_files: ["mix.exs"],
      detect: [{:package, :ex_doc}]
    ],

    ## Sobelow (Security)
    sobelow: [
      command: "mix sobelow --config",
      env: %{},
      cd: nil,
      require_files: ["mix.exs"],
      detect: [{:package, :sobelow}]
    ],

    ## Hex Audit (Security - built-in)
    hex_audit: [
      command: "mix hex.audit",
      env: %{},
      cd: nil,
      require_files: ["mix.lock"]
    ],

    ## Mix Audit (Security)
    mix_audit: [
      command: "mix deps.audit",
      env: %{},
      cd: nil,
      require_files: ["mix.lock"],
      detect: [{:package, :mix_audit}]
    ],

    ## Test Coverage
    test_coverage: [
      command: "mix coveralls.html",
      env: %{},
      cd: nil,
      require_files: ["mix.exs"],
      detect: [{:package, :excoveralls}]
    ]
  ]
]
