# ExkPasswd repository contract

Read this file before editing. It owns repository-wide agent policy; use the
linked project documentation for the details relevant to the task.

## Scope and Git

- Preserve unrelated changes and existing local client settings.
- Never push branches, tags, commits, or other Git refs. The user performs all
  pushes manually.
- Never change repository visibility. If visibility blocks an outcome, report
  the user-managed blocker and continue work that does not depend on it.
- Use Conventional Commits: `type(optional scope): description`. `git_ops` uses
  these messages for releases. Do not add AI attribution or `Co-Authored-By`.
- Report decisions, sources, completed checks, and material limitations in chat.
  Distinguish checks actually run from planned work or inferred behavior.

## Skill discovery

Canonical skills live in tracked `.agents/skills/<name>/SKILL.md`. Select and
apply matching skills automatically from their descriptions as the task,
changed mechanism, or delivery stage requires. The user does not invoke skills
or choose slash commands. Keep implicit invocation enabled.

Use native discovery where supported. Clients without skill discovery must
inspect the `name` and `description` of `.agents/skills/*/SKILL.md`, then read
and apply matching files themselves. Load supporting references only when the
active workflow needs them; resolve relative links from the containing file.

Claude Code discovers skills through ignored individual directory symlinks at
`.claude/skills/<name>` pointing to `../../.agents/skills/<name>`. Preserve local
entries. When adding or renaming a canonical skill, create its link if the
entry is absent and repair links that target repository-owned skills. Do not
replace unrelated local files or links. Keep all of `.claude/` ignored.

## Project boundaries

ExkPasswd is an Elixir 1.16+ password-generation library with no external runtime
dependencies. Keep core functionality in Elixir stdlib and `:crypto`; justify
any new development or test dependency. Development tooling needs a newer
Elixir release; use the quality-gate runtime in
[CI](.github/workflows/ci.yml) when running `mix check`.

- `lib/exk_passwd.ex` owns the public API and delegates generation and analysis.
- `Config`, `Config.Schema`, and `Validator` own construction and validation.
  Preserve validation of manually built or modified structs at generation time.
- `Password`, `Batch`, `Token`, `Buffer`, and `Random` own generation and random
  choices. Preserve equivalent behavior across single and buffered generation.
- `Dictionary` compiles EFF ranges and case variants into tuples; custom
  dictionaries use `:persistent_term`. Load them during provisioning or startup,
  not in hot paths. Built-in presets are compile-time configurations; only
  runtime preset registration requires the `Config.Presets` Agent.
- `Transform` implementations own word transformations; `Entropy` and `Strength`
  own analysis. See [usage rules](usage-rules.md) and the protocol documentation
  when changing transformation order or custom transforms.
- `browser/` is a separate AtomVM consumer outside the Hex package. Read
  [its README](browser/README.md) before changing portability branches, browser
  protocol behavior, or browser builds. Keep the production cryptographic source
  and native library behavior intact.

## Security and implementation

- Route production password randomness through `Random.Source` and its default
  `CryptoSource`, backed by `:crypto.strong_rand_bytes/1`. Fail if secure
  randomness is unavailable; never add a predictable fallback.
- Use `ExkPasswd.Random.integer/1` or the existing buffered rejection sampler for
  bounded selection. Do not use modulo-only reduction, `:rand`, `Enum.random/1`,
  timestamps, or user-provided seeds for password material.
- Deterministic fixtures belong in the existing test-only source seam. Never
  enable that seam in production or log passwords, selected words, or buffers.
- Preserve NFC normalization, duplicate handling, transformed-length filtering,
  and safe dictionary names. Do not create atoms from untrusted input.
- Recommend at least three words for ordinary use. Preserve the documented
  1–10 word configuration range and constrained presets.
- Read [the security model](docs/SECURITY.md) when changing randomness,
  dictionaries, composition, transforms, or entropy. Preserve collision
  deductions and the distinction between conservative seen entropy and the
  blind heuristic. Project ratings are not NIST or OWASP certifications.
- Prefer pattern matching, pipelines, and focused functions. Return tagged
  tuples for expected validation errors, with actionable messages; keep bang
  functions' raising behavior consistent. Use `Enum.join/2` or iodata for string
  assembly and measure performance changes with the existing `bench/` tools.
- All public modules need `@moduledoc`; public functions need `@spec`, `@doc`,
  parameters, return/error behavior, and examples. Add doctests where practical.
  Update user-facing documentation when behavior changes.

## Validation and delivery

Run the complete gate and require every configured tool to pass before declaring
completion or committing:

```sh
mix check
```

[`.check.exs`](.check.exs) owns its configured commands: warnings-as-errors
compilation, formatting, strict Credo, dependency audits, Dialyzer, Doctor,
documentation warnings, and tests with the 95% overall coverage floor. Use
focused commands such as `mix test test/exk_passwd/random_test.exs`, `mix format`,
or `mix credo --strict` while iterating. Test public APIs, errors, and changed
security boundaries; maintain full coverage of security-critical selection and
randomness. Statistical smoke tests and text searches do not prove security or
semantic correctness. Review the relevant implementation and test behavior.

For an explicitly requested release, follow
[the release process](CONTRIBUTING.md#release-process). `mix release` updates
the changelog and versions and creates a local commit and tag. Leave every push
to the user. The publishing workflow verifies the exact version/tag/commit,
runs the gate, and exposes the Hex credential only to the publishing step.
