# ExkPasswd

ExkPasswd is an Elixir library for generating memorable passwords from random
words. It uses `:crypto.strong_rand_bytes/1`, has no runtime dependencies, and
supports custom dictionaries and word transforms.

[![Test Suite](https://github.com/futhr/exk_passwd/workflows/Test%20Suite/badge.svg)](https://github.com/futhr/exk_passwd/actions)
[![Hex.pm](https://img.shields.io/hexpm/v/exk_passwd.svg)](https://hex.pm/packages/exk_passwd)
[![Documentation](https://img.shields.io/badge/docs-hexdocs-purple.svg)](https://hexdocs.pm/exk_passwd)
[![License](https://img.shields.io/badge/License-BSD_2--Clause-blue.svg)](LICENSE.md)
[![Elixir](https://img.shields.io/badge/elixir-%3E%3D1.16-blueviolet.svg)](https://elixir-lang.org)

The design follows the XKPasswd idea: choose independent words with a secure
random source, then add separators, digits, or transformations when a target
system requires them. Security comes from the number of reachable random
outcomes—not from hiding the dictionary or making the result look complicated.

## Installation

```elixir
def deps do
  [
    {:exk_passwd, "~> 0.2.0"}
  ]
end
```

## Quick start

```elixir
# Default preset
ExkPasswd.generate()

# Five-word passphrase
ExkPasswd.generate(:xkcd)
ExkPasswd.generate("xkcd")

# Preset with overrides
ExkPasswd.generate(:xkcd, num_words: 6)

# A custom configuration
config =
  ExkPasswd.Config.new!(
    num_words: 4,
    word_length: 5..7,
    case_transform: :capitalize,
    separator: "-",
    digits: {2, 2},
    padding: %{char: "!", before: 1, after: 1}
  )

ExkPasswd.generate(config)
```

Configuration constructors reject unknown, duplicate, and malformed options.
Public generation functions also validate directly assembled `%Config{}`
structs before using them.

## Presets

The entropy figures below are approximate seen min-entropy for the current EFF
dictionary and preset definitions. They assume an attacker knows the generator,
dictionary, and configuration.

| Preset | Purpose | Approx. seen entropy |
| --- | --- | ---: |
| `:default` | Three words, digits, separators, and padding | 59.4 bits |
| `:xkcd` | Five hyphen-separated words | 67.9 bits |
| `:web32` | Output no longer than 32 characters | 65.0 bits |
| `:web16` | Compatibility with a 16-character maximum | 37.0 bits |
| `:wifi` | 63 printable ASCII characters for a WPA/WPA2 passphrase | 105.2 bits |
| `:apple_id` | Meets Apple Account character-composition rules | 54.7 bits |
| `:security` | Fake answers for legacy security-question fields | 77.1 bits |

`web16` is a compatibility fallback, not a general recommendation. The
`security` preset produces random fake answers; knowledge-based authentication
itself is not recommended by current NIST guidance.

The Wi-Fi preset emits 63 printable ASCII characters. WPA/WPA2-Personal accepts
an 8–63 character ASCII passphrase; a 64-character value has a different meaning
when it is a hexadecimal raw PSK. See the [`wpa-psk(8)` manual](https://man.openbsd.org/wpa-psk).

Apple currently requires at least eight characters, upper- and lowercase
letters, and a number. The preset guarantees those properties, but Apple may
also reject common or otherwise policy-blocked passwords. See
[Apple's current account guidance](https://support.apple.com/en-mide/102614).

## Configuration

```elixir
ExkPasswd.Config.new!(
  num_words: 3,                # 1..10
  word_length: 4..8,           # ascending range, maximum 50
  case_transform: :alternate,  # :none, :alternate, :capitalize, :invert,
                               # :lower, :upper, or :random
  separator: "-",              # one value or a set of possible symbols
  digits: {2, 2},              # before and after, each 0..5
  padding: %{
    char: "!@#",
    before: 1,
    after: 1,
    to_length: 0               # positive values set a minimum; never truncates
  },
  substitutions: %{"a" => "@", "e" => "3"},
  substitution_mode: :none,    # :none, :always, or :random
  dictionary: :eff,
  meta: %{transforms: []}
)
```

Separators and padding characters accept punctuation and symbols, not letters or
digits. A separator or padding string with several graphemes is treated as a set
from which one value is selected.

`padding.to_length` is a minimum output length. If the generated password is
already longer, ExkPasswd returns it intact. Silent truncation would discard
random words or digits and overstate the resulting security.

## Custom dictionaries

The bundled EFF list is a convenient default, not a restriction. Applications
can provide a dictionary for any language or domain:

```elixir
words = ["casa", "perro", "gato", "libro", "nube"]
ExkPasswd.Dictionary.load_custom(:spanish, words)

config =
  ExkPasswd.Config.new!(
    dictionary: :spanish,
    word_length: 4..5,
    num_words: 4,
    separator: "-"
  )

ExkPasswd.generate(config)
```

Custom words must be non-empty valid UTF-8 strings. ExkPasswd normalizes them to
NFC and rejects duplicates after normalization. Case-transformed duplicates are
stored once so selection remains uniform over reachable outputs.

Custom dictionaries live in `:persistent_term`. Load them during application
startup rather than in a request path: writes to `:persistent_term` trigger a
global garbage-collection scan. The caller remains responsible for dictionary
quality, size, memorability, and suitability for the intended users.

## Substitutions and transforms

Simple substitutions can be configured directly:

```elixir
config =
  ExkPasswd.Config.new!(
    substitutions: %{"a" => "@", "e" => "3", "o" => "0"},
    substitution_mode: :random
  )

ExkPasswd.generate(config)
```

Random substitution adds entropy only when the substituted and original outputs
are distinct. Deterministic substitutions may reduce the output space by making
different dictionary words collide; the entropy calculation accounts for that.

More involved transformations implement `ExkPasswd.Transform` and go in
`config.meta.transforms`:

```elixir
ExkPasswd.Dictionary.load_custom(:japanese, ["さくら", "やま", "うみ", "そら"])

config =
  ExkPasswd.Config.new!(
    dictionary: :japanese,
    word_length: 2..6,
    word_length_bounds: 1..10,
    case_transform: :none,
    meta: %{transforms: [%ExkPasswd.Transform.Romaji{}]}
  )
```

Built-in Pinyin and Romaji transforms are deterministic and may be many-to-one.
The seen-entropy model counts their reachable outputs rather than assuming every
source word remains distinguishable. Unmapped characters pass through unchanged,
so validate a language dictionary before relying on ASCII output.

## Batch generation

```elixir
config = ExkPasswd.Config.Presets.get(:default)

ExkPasswd.Batch.generate_batch(100, config)
ExkPasswd.Batch.generate_unique_batch(100, config, max_attempts: 10_000)
ExkPasswd.Batch.generate_parallel(10_000, config, workers: 4)
```

The batch path buffers secure random bytes. Whether it is faster than individual
generation depends on batch size, runtime version, and hardware; use the included
Benchee scripts for measurements on the target system. Unique generation raises
if it cannot find the requested number of distinct outputs within `max_attempts`.

## Entropy and strength reports

```elixir
config = ExkPasswd.Config.Presets.get(:xkcd)
password = ExkPasswd.generate(config)

ExkPasswd.Entropy.calculate(password, config)
ExkPasswd.Strength.analyze(password, config)
```

The report contains two different quantities:

- `seen` is conservative min-entropy over the configured generator's reachable
  outputs. It includes known case, substitution, Pinyin, and Romaji collisions.
- `blind` is a character-class search-space heuristic for the observed string.
  It is not measured entropy and should not be used to infer how a human-chosen
  password was generated.

The `weak`, `fair`, `good`, and `excellent` bands are project-defined convenience
labels. Crack-time strings use a simple one-billion-guesses-per-second comparison
model; real rates depend on online throttling or the password-hashing scheme.

Current NIST guidance emphasizes length, blocklists, rate limiting, and avoiding
composition rules for user-chosen passwords. OWASP also says passwords must not
be silently truncated. See [NIST SP 800-63B](https://pages.nist.gov/800-63-4/sp800-63b.html)
and the [OWASP Authentication Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html).

## Interactive examples

- [Quick start](notebooks/quickstart.livemd)
- [Advanced configuration](notebooks/advanced.livemd)
- [Security model](notebooks/security.livemd)
- [Chinese/Pinyin](notebooks/i18n_chinese.livemd)
- [Japanese/Romaji](notebooks/i18n_japanese.livemd)
- [Benchmarks](notebooks/benchmarks.livemd)
- [Contributing](notebooks/contributing.livemd)

## Development

```bash
mix setup
mix format
mix credo --strict
mix test
mix coveralls.html
mix dialyzer
mix doctor
mix docs
mix deps.audit
```

Benchmark scripts are available as `mix bench.password`, `mix bench.dict`,
`mix bench.batch`, and `mix bench.all`. Results are local measurements, not API
guarantees.

## License

BSD 2-Clause. See [LICENSE.md](LICENSE.md).
