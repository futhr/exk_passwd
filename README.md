# ExkPasswd

> ExkPasswd generates strong passwords by combining cryptographically random
> words with optional digits, symbols, and transformations. The result is easier
> to remember than a random character string without hiding how its security is
> measured.

[![Test Suite](https://github.com/futhr/exk_passwd/actions/workflows/ci.yml/badge.svg)](https://github.com/futhr/exk_passwd/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/futhr/exk_passwd/graph/badge.svg?token=HXDYFULIMN)](https://codecov.io/gh/futhr/exk_passwd)
[![Hex.pm](https://img.shields.io/hexpm/v/exk_passwd.svg?label=Hex.pm)](https://hex.pm/packages/exk_passwd)
[![Documentation](https://img.shields.io/badge/docs-hexdocs-purple.svg)](https://hexdocs.pm/exk_passwd)
[![License](https://img.shields.io/badge/License-BSD_2--Clause-blue.svg)](LICENSE.md)
[![Elixir](https://img.shields.io/badge/elixir-%3E%3D1.16-blueviolet.svg)](https://elixir-lang.org)

---

## Try It Interactively

The Livebook notebooks are executable guides, not extra API reference pages.
Start with the quick-start notebook in a browser:

[![Run in Livebook](https://livebook.dev/badge/v1/blue.svg)](https://livebook.dev/run?url=https%3A%2F%2Fraw.githubusercontent.com%2Ffuthr%2Fexk_passwd%2Fmain%2Fnotebooks%2Fquickstart.livemd)

- **[Quick Start](https://livebook.dev/run?url=https%3A%2F%2Fraw.githubusercontent.com%2Ffuthr%2Fexk_passwd%2Fmain%2Fnotebooks%2Fquickstart.livemd)** -
  Generate passwords and explore the built-in presets.
- **[Advanced Usage](https://livebook.dev/run?url=https%3A%2F%2Fraw.githubusercontent.com%2Ffuthr%2Fexk_passwd%2Fmain%2Fnotebooks%2Fadvanced.livemd)** -
  Work with case modes, padding, substitutions, and custom dictionaries.
- **[Security Analysis](https://livebook.dev/run?url=https%3A%2F%2Fraw.githubusercontent.com%2Ffuthr%2Fexk_passwd%2Fmain%2Fnotebooks%2Fsecurity.livemd)** -
  Compare generator-aware min-entropy with the blind search-space estimate.
- **[Chinese and Pinyin](https://livebook.dev/run?url=https%3A%2F%2Fraw.githubusercontent.com%2Ffuthr%2Fexk_passwd%2Fmain%2Fnotebooks%2Fi18n_chinese.livemd)** -
  Load a Chinese dictionary and produce toneless ASCII Pinyin.
- **[Japanese and Romaji](https://livebook.dev/run?url=https%3A%2F%2Fraw.githubusercontent.com%2Ffuthr%2Fexk_passwd%2Fmain%2Fnotebooks%2Fi18n_japanese.livemd)** -
  Generate from Kana and produce keyboard-friendly Romaji.
- **[Benchmarks](https://livebook.dev/run?url=https%3A%2F%2Fraw.githubusercontent.com%2Ffuthr%2Fexk_passwd%2Fmain%2Fnotebooks%2Fbenchmarks.livemd)** -
  Measure single and batch generation on your own runtime and hardware.

---

## History & Inspiration

The word-based password idea was popularized by
[Randall Munroe's XKCD comic #936](https://xkcd.com/936/). It shows why a
sequence of independently chosen words can be both easier to remember and
harder to guess than a short password built from predictable character tricks.

<p align="center">
  <a href="https://xkcd.com/936/">
    <img src="https://raw.githubusercontent.com/futhr/exk_passwd/main/priv/static/xkcd.png" alt="XKCD #936, Password Strength" width="740">
  </a>
  <br>
  <em>XKCD #936, “Password Strength,” by Randall Munroe,
  <a href="https://xkcd.com/license.html">CC BY-NC 2.5</a> (separate from the library license).</em>
</p>

The comic inspired [Bart Busschots](https://www.bartbusschots.ie/) to create
[Crypt::HSXKPasswd](https://github.com/bbusschots/hsxkpasswd), a configurable
Perl implementation of the idea. The concept was later ported to JavaScript and
then to Elixir by [Michael Westbay](https://github.com/westbaystars).

ExkPasswd continues that lineage with the
[EFF Large Wordlist](https://www.eff.org/deeplinks/2016/07/new-wordlists-random-passphrases),
unbiased cryptographic sampling, strict configuration validation, custom
dictionaries, extensible transforms, batch generation, and explicit entropy
analysis.

---

## Why Word-Based Passwords?

A short random string such as `x4$9Kp2m` can be difficult to remember and type.
A human-created variation is often worse because substitutions and punctuation
tend to follow familiar patterns.

A generated password such as
`aviator-DANDER-REACTOR-GRATING-STARFISH` has different advantages:

- Real words are easier to read, type, and remember.
- Several independent choices create a large output space.
- Length comes naturally instead of being added through repetition.
- The dictionary and generation rules can be public without making a generated
  password predictable.

Words are not magic. A quotation, lyric, idiom, or phrase chosen by a person is
not equivalent to independently sampled words. ExkPasswd's security comes from
the random process and the number of reachable outputs, not from obscurity or
visual complexity.

---

## Features

### Core Features

- **Cryptographically secure randomness** - All password choices ultimately use
  `:crypto.strong_rand_bytes/1`; integer ranges use rejection sampling to avoid
  modulo bias.
- **EFF Large Wordlist** - Ships with 7,772 lowercase words derived from the
  canonical 7,776-entry list.
- **Zero runtime dependencies** - Uses only Elixir/Erlang and `:crypto` at
  runtime.
- **Seven built-in presets** - Covers memorable defaults and common compatibility
  constraints.
- **Strict configuration** - Rejects unknown, duplicate, malformed, and
  unsatisfiable options before generation.
- **Custom dictionaries** - Supports normalized UTF-8 wordlists loaded at
  application startup.

### Advanced Features

- **Indexed word selection** - Uses precomputed tuples for common EFF word
  ranges.
- **Buffered batch generation** - Reduces random-source calls for suitable
  workloads while preserving unbiased selection.
- **Parallel generation** - Splits large batches across configurable workers.
- **Generator-aware entropy** - Measures reachable outputs and known collisions
  instead of awarding generic complexity points.
- **Substitutions and transforms** - Includes case handling, character
  substitution, Pinyin, and Romaji, plus a protocol for custom transforms.
- **Runtime presets** - Applications can supervise a registry and compose their
  own named configurations.

---

## Installation

Add `exk_passwd` to the dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:exk_passwd, "~> 0.3.1"}
  ]
end
```

Then fetch the dependency:

```bash
mix deps.get
```

---

## Quick Start

### Basic Usage

Every output below is random; the comments show real examples rather than fixed
return values.

```elixir
# Generate with the default preset
ExkPasswd.generate()
#=> "..83=cocoa=ABDOMEN=tracing=22.."

# Use a preset by atom
ExkPasswd.generate(:xkcd)
#=> "aviator-DANDER-REACTOR-GRATING-STARFISH"

# Preset names can also be strings
ExkPasswd.generate("wifi") |> String.length()
#=> 63

# Start from a preset and override selected options
ExkPasswd.generate(:xkcd, num_words: 6)
#=> "mobile-handful-EATABLE-EXIT-NUTRIENT-PUPPET"
```

### Custom Configuration

Pass a keyword list directly:

```elixir
ExkPasswd.generate(
  num_words: 4,
  word_length: 5..7,
  case_transform: :capitalize,
  separator: "-",
  digits: {2, 2},
  padding: %{char: "!", before: 1, after: 1}
)
#=> "!86-Arrive-Amnesty-Bauble-Kosher-51!"
```

Or construct and reuse a validated configuration:

```elixir
config =
  ExkPasswd.Config.new!(
    num_words: 4,
    word_length: 5..7,
    case_transform: :capitalize,
    separator: "-",
    digits: {2, 2},
    padding: %{char: "!", before: 1, after: 1}
  )

password = ExkPasswd.generate(config)
report = ExkPasswd.Entropy.calculate(password, config)
```

Use `ExkPasswd.Config.new/1` when invalid user input should return an error tuple
instead of raising.

---

## Available Presets

The entropy figures are approximate **seen min-entropy** for the current EFF
dictionary and preset definitions. They assume an attacker knows the library,
dictionary, and full configuration.

### `:default`

Three words with alternating case, two digits on each side, random separators,
and symbol padding. Approximate seen entropy: **59.4 bits**.

```elixir
ExkPasswd.generate(:default)
#=> "..83=cocoa=ABDOMEN=tracing=22.."
```

### `:xkcd`

Five words separated by hyphens with independently randomized word casing.
Approximate seen entropy: **67.9 bits**.

```elixir
ExkPasswd.generate(:xkcd)
#=> "aviator-DANDER-REACTOR-GRATING-STARFISH"
```

### `:web32`

Four short words plus digits and symbols, constructed to remain at or below 32
characters. Approximate seen entropy: **65.0 bits**.

```elixir
password = ExkPasswd.generate(:web32)
String.length(password) <= 32
#=> true
```

### `:web16`

A compatibility fallback for systems that impose a 16-character maximum.
Approximate seen entropy: **37.0 bits**, so it is not a general recommendation.

```elixir
password = ExkPasswd.generate(:web16)
String.length(password) <= 16
#=> true
```

### `:wifi`

Generates exactly 63 printable ASCII characters for a WPA/WPA2-Personal
passphrase. Approximate seen entropy: **105.2 bits**.

```elixir
password = ExkPasswd.generate(:wifi)
String.length(password)
#=> 63
```

WPA/WPA2-Personal accepts an 8–63 character ASCII passphrase. A 64-character
hexadecimal value represents a raw PSK rather than a longer passphrase. See the
[`wpa-psk(8)` manual](https://man.openbsd.org/OpenBSD-4.8/wpa-psk).

### `:apple_id`

Generates upper- and lowercase letters, numbers, and punctuation available on
standard Apple keyboards. Approximate seen entropy: **54.7 bits**.

```elixir
ExkPasswd.generate(:apple_id)
#=> "?32.unmixed.SPEECH.sway.73?"
```

The preset guarantees the documented composition properties, but Apple may
still reject common or otherwise policy-blocked passwords. See
[Apple's account security guidance](https://support.apple.com/en-us/102614).

### `:security`

Generates a random fake answer for a legacy security-question field.
Approximate seen entropy: **77.1 bits**.

```elixir
ExkPasswd.generate(:security)
#=> "blip italics pawing unworthy name recliner!"
```

Knowledge-based authentication itself is not recommended by current NIST
guidance. When a service still requires an answer, store the generated value as
you would any other password.

---

## Configuration Options

All generation settings live in `ExkPasswd.Config`:

```elixir
ExkPasswd.Config.new!(
  num_words: 3,                # 1..10
  word_length: 4..8,           # ascending range, maximum 50
  word_length_bounds: nil,     # custom bounds for non-Latin dictionaries
  case_transform: :alternate,  # see the modes below
  separator: "-",              # one symbol or a set of possible symbols
  digits: {2, 2},              # before and after, each 0..5
  padding: %{
    char: "!@#",
    before: 1,
    after: 1,
    to_length: 0               # 0 disables minimum-length padding
  },
  substitutions: %{"a" => "@", "e" => "3"},
  substitution_mode: :none,    # :none, :always, or :random
  dictionary: :eff,
  meta: %{transforms: []},
  validators: []
)
```

Separators and padding characters accept punctuation and symbols, not letters
or digits. A string containing several graphemes is treated as a set of possible
characters.

`padding.to_length` is a minimum length, never a truncation rule. If the natural
password is already longer, ExkPasswd returns it intact rather than discarding
random words or digits.

### Case Transformations

- `:none` - Leave each dictionary word unchanged.
- `:lower` - Convert words to lowercase.
- `:upper` - Convert words to uppercase.
- `:capitalize` - Uppercase the first grapheme of each word.
- `:invert` - Lowercase the first grapheme and uppercase the remainder.
- `:alternate` - Alternate lower- and uppercase words.
- `:random` - Independently choose lower- or uppercase for each word.

### Character Substitutions

```elixir
config =
  ExkPasswd.Config.new!(
    substitutions: %{"a" => "@", "e" => "3", "o" => "0"},
    substitution_mode: :random
  )

ExkPasswd.generate(config)
#=> "__15-clone-BONSAI-m0l3cul3-22__"
```

Random substitution receives entropy credit only when original and substituted
outputs are distinct. Deterministic substitution can reduce the output space
when multiple source words collapse to the same result; the entropy model
accounts for those collisions.

---

## Security

### Cryptographic Randomness

All password choices ultimately use `:crypto.strong_rand_bytes/1`. Integer
ranges, including buffered batch generation, use rejection sampling so
non-power-of-two ranges remain uniform.

ExkPasswd never uses `:rand`, `Enum.random/1`, timestamps, process identifiers,
or a caller-provided seed for password material. This does not protect a system
whose operating system, runtime, or hardware random source is compromised.

### Dictionary & Security Model

The bundled dictionary contains 7,772 lowercase ASCII words derived from the EFF
Large Wordlist. Four hyphenated entries are omitted so `-` can serve as an
unambiguous separator. Selecting from the full bundled list would provide about
12.92 bits per word, but length filters and transforms can change the effective
pool.

The security assumptions are deliberately public: an attacker may know the
library, dictionary, preset, and every configuration option. Only the random
choices are secret.

For ambiguous word boundaries, `details.composition_loss` deducts possible
assembly collisions. Use the reported total rather than adding component fields.

For provenance, checksums, and the exact threat model, see
[`docs/SECURITY.md`](docs/SECURITY.md).

### Understanding Entropy Reports

ExkPasswd reports two different quantities:

- `seen` is conservative min-entropy over the configured generator's reachable
  outputs. It accounts for dictionary filters and known collisions from case
  conversion, substitutions, Pinyin, and Romaji.
- `blind` is a character-class search-space heuristic for the observed string.
  It is useful as a comparison, but it is not measured entropy and should not be
  used to assess a human-chosen password.

The `weak`, `fair`, `good`, and `excellent` ratings are project-defined
presentation bands, not NIST or OWASP standards. Crack-time strings use a simple
one-billion-guesses-per-second comparison model; actual rates depend on online
throttling, MFA, password hashing, hardware, and breach conditions.

### What ExkPasswd Does Not Solve

This library generates passwords. It does not store or hash them, check breach
blocklists, prevent phishing or keylogging, provide rate limiting or MFA, or
detect whether a destination silently normalizes or truncates input.

Use a password manager when possible, enable MFA for important accounts, and
test the exact destination field before relying on whitespace, Unicode, or
uncommon punctuation.

Current verifier guidance emphasizes length, blocklists, rate limiting, and
support for long passphrases:

- [NIST SP 800-63B](https://pages.nist.gov/800-63-4/sp800-63b.html)
- [OWASP Authentication Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html)
- [OWASP Password Storage Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html)

---

## API Reference

The complete API documentation lives on
[HexDocs](https://hexdocs.pm/exk_passwd). These are the main entry points.

### Password Generation

#### `ExkPasswd.generate/0`

Generates one password with the `:default` preset:

```elixir
password = ExkPasswd.generate()
is_binary(password)
#=> true
```

#### `ExkPasswd.generate/1`

Accepts a preset atom, preset string, keyword options, or a validated config:

```elixir
ExkPasswd.generate(:xkcd)
ExkPasswd.generate("xkcd")
ExkPasswd.generate(num_words: 4, separator: "-")

config = ExkPasswd.Config.new!(num_words: 4, separator: "-")
ExkPasswd.generate(config)
```

#### `ExkPasswd.generate/2`

Starts with a built-in or runtime preset and applies validated overrides:

```elixir
ExkPasswd.generate(:xkcd, num_words: 6, case_transform: :lower)
```

### Configuration

`new/1` returns a tagged tuple for expected input errors:

```elixir
{:ok, config} = ExkPasswd.Config.new(num_words: 4)

{:error, reason} = ExkPasswd.Config.new(num_words: 0)
String.contains?(reason, "num_words")
#=> true
```

`new!/1` returns the config or raises `ArgumentError`:

```elixir
config = ExkPasswd.Config.new!(num_words: 4)
```

Constructors reject unknown and duplicate options. Public generation functions
also validate `%ExkPasswd.Config{}` values assembled directly by callers.

### Presets

Built-in presets work without starting a process:

```elixir
ExkPasswd.Config.Presets.get(:xkcd)
ExkPasswd.Config.Presets.get("wifi")
ExkPasswd.Config.Presets.list()
```

Runtime registration requires the preset registry in your supervision tree:

```elixir
children = [
  {ExkPasswd.Config.Presets, []}
]
```

You can register a complete config or compose from an existing preset:

```elixir
ExkPasswd.Config.Presets.register(
  :six_words,
  :xkcd,
  num_words: 6,
  case_transform: :lower
)

ExkPasswd.generate(:six_words)
```

### Batch Generation

```elixir
config = ExkPasswd.Config.Presets.get(:default)

# Buffered generation
ExkPasswd.Batch.generate_batch(100, config)

# Enforce uniqueness with a bounded retry budget
ExkPasswd.Batch.generate_unique_batch(
  100,
  config,
  max_attempts: 10_000
)

# Split a large batch across worker processes
ExkPasswd.Batch.generate_parallel(10_000, config, workers: 4)
```

Buffering is not guaranteed to be faster for every workload. Batch size,
runtime version, and hardware all matter, so use the included benchmarks on the
target system. Unique generation raises if it cannot produce the requested
number of distinct values within `max_attempts`.

### Entropy & Strength

```elixir
config = ExkPasswd.Config.Presets.get(:xkcd)
password = ExkPasswd.generate(config)

entropy = ExkPasswd.Entropy.calculate(password, config)
Float.round(entropy.seen, 1)
#=> 67.9

strength = ExkPasswd.Strength.analyze(password, config)
Map.keys(strength) |> Enum.sort()
#=> [:entropy_bits, :rating, :score]

ExkPasswd.Strength.rating(password, config)
#=> :good
```

Top-level delegates are also available as `ExkPasswd.calculate_entropy/2`,
`ExkPasswd.analyze_strength/2`, and `ExkPasswd.strength_rating/2`.

### Custom Dictionaries

```elixir
words = ["casa", "perro", "gato", "libro", "nube"]
ExkPasswd.Dictionary.load_custom(:spanish, words)

config =
  ExkPasswd.Config.new!(
    dictionary: :spanish,
    word_length: 4..5,
    num_words: 4,
    case_transform: :lower,
    separator: "-",
    digits: {0, 0},
    padding: %{char: "", before: 0, after: 0, to_length: 0}
  )

ExkPasswd.generate(config)
#=> "gato-casa-nube-libro"
```

Custom words must be non-empty valid UTF-8 strings. They are normalized to NFC,
and duplicates after normalization are rejected. Case-output duplicates are
stored once so selection remains uniform over reachable outputs.

Custom dictionaries live in `:persistent_term`. Load them during application
startup rather than in a request path because writes trigger a global
garbage-collection scan. The application remains responsible for dictionary
quality, size, memorability, and content.

### Transform Protocol

Simple substitutions belong directly in the config. More involved
transformations implement `ExkPasswd.Transform` and go in
`config.meta.transforms`.

The bundled Romaji transform can make a Kana dictionary typeable on an ASCII
keyboard:

```elixir
ExkPasswd.Dictionary.load_custom(
  :japanese,
  ["さくら", "やま", "うみ", "そら"]
)

config =
  ExkPasswd.Config.new!(
    dictionary: :japanese,
    word_length: 2..6,
    word_length_bounds: 1..10,
    num_words: 3,
    case_transform: :none,
    separator: "-",
    digits: {0, 0},
    padding: %{char: "", before: 0, after: 0, to_length: 0},
    meta: %{transforms: [%ExkPasswd.Transform.Romaji{}]}
  )

ExkPasswd.generate(config)
#=> "sakura-sora-umi"
```

Pinyin and Romaji are deterministic and can be many-to-one. Unmapped characters
pass through unchanged. Validate every custom language dictionary if the
destination requires ASCII; the seen-entropy model counts the reachable
transformed outputs rather than assuming every source word stays distinct.

---

## Development

### Quick Reference

```bash
# Setup
mix setup

# Complete required quality gate
mix check

# Useful focused commands while iterating
mix format
mix credo --strict
mix test
mix coveralls.html
mix dialyzer
mix doctor
mix docs
mix deps.audit
```

### Benchmarks

```bash
mix bench.password
mix bench.dict
mix bench.batch
mix bench.all
```

The checked-in benchmark reports are measurements from one recorded environment,
not API guarantees. Re-run the suites on the deployment runtime and hardware
before drawing performance conclusions.

### Interactive Contributor Guide

The contributor notebook is intentionally separate from the user tutorials:

[![Run the contributor guide in Livebook](https://livebook.dev/badge/v1/blue.svg)](https://livebook.dev/run?url=https%3A%2F%2Fraw.githubusercontent.com%2Ffuthr%2Fexk_passwd%2Fmain%2Fnotebooks%2Fcontributing.livemd)

It provides an executable architecture tour. The terminal quality gates remain
the source of truth for contributions.

---

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request. Keep
security-sensitive changes small, document public APIs, and include tests for
success, failure, and relevant edge cases.

Commit messages follow
[Conventional Commits](https://www.conventionalcommits.org/):

```text
feat: add a new preset
fix(random): reject biased buffered samples
docs: clarify the entropy model
```

---

## Releasing

Releases are managed with `git_ops`:

1. Run the complete project checks with `mix check`.
2. Run `mix release` to update the changelog and version, commit, and tag.
3. Push the release commit and tag with `git push --follow-tags`.

The publish workflow verifies the exact project-version tag and tagged commit,
runs the same `mix check` gate, and exposes the Hex API key only to the final
publish step.

---

## Resources

- [Hex package](https://hex.pm/packages/exk_passwd)
- [HexDocs](https://hexdocs.pm/exk_passwd)
- [Security model](docs/SECURITY.md)
- [Livebook setup](docs/LIVEBOOK_SETUP.md)
- [Changelog](CHANGELOG.md)
- [Issue tracker](https://github.com/futhr/exk_passwd/issues)
- [Original Perl module](https://github.com/bbusschots/hsxkpasswd)
- [EFF random-passphrase wordlists](https://www.eff.org/deeplinks/2016/07/new-wordlists-random-passphrases)
- [XKCD comic #936](https://xkcd.com/936/)

---

## Acknowledgments

- [Randall Munroe](https://xkcd.com/936/) for the comic that made the core idea
  memorable.
- [Bart Busschots](https://github.com/bbusschots/hsxkpasswd) for the original
  Crypt::HSXKPasswd implementation.
- [Michael Westbay](https://github.com/westbaystars) for bringing the project to
  Elixir.
- The [Electronic Frontier Foundation](https://www.eff.org/deeplinks/2016/07/new-wordlists-random-passphrases)
  for its random-passphrase wordlists.

---

## License

ExkPasswd is available under the BSD 2-Clause License. See
[LICENSE.md](LICENSE.md).
