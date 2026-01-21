[
  ## Don't run tools concurrently
  parallel: false,

  ## Don't print summary
  skipped: false,

  tools: [
    {:compiler, "mix compile --warnings-as-errors"},
    {:formatter, "mix format --check-formatted"},
    {:credo, "mix credo --strict"},
    {:ex_unit, false},
    {:test, command: "mix test", env: %{"MIX_ENV" => "test"}},
    {:hex_audit, "mix hex.audit"},
    {:mix_audit, "mix deps.audit"},
    {:dialyzer, false},
    {:doctor, "mix doctor --summary"},
    {:ex_doc, false},
    {:sobelow, false}
  ]
]
