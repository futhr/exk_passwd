# ExkPasswd usage rules

ExkPasswd generates memorable passwords from cryptographically selected words,
separators, digits, and padding. It requires Elixir 1.16 or newer and has no
external runtime dependencies.

## Generate passwords

```elixir
ExkPasswd.generate()
ExkPasswd.generate(:xkcd)
ExkPasswd.generate("wifi")
ExkPasswd.generate(:xkcd, num_words: 6)

config = ExkPasswd.Config.new!(num_words: 4, separator: "-")
ExkPasswd.generate(config)
ExkPasswd.generate_batch(100, config)
ExkPasswd.generate_unique_batch(100, config)
ExkPasswd.generate_parallel(1000, config)
```

`separator` is a pool of graphemes: one is selected and reused throughout each
password. An empty pool omits separators. Repeated graphemes weight the choice;
`"!!?"` selects `"!"` with probability 2/3.

`padding.char` is also a pool. Fixed padding repeats one selected grapheme on
both sides. `padding.to_length` sets a minimum length; it never truncates output
and takes precedence over `before` and `after`.

```elixir
config = ExkPasswd.Config.new!(
  num_words: 4,
  word_length: 4..8,
  case_transform: :alternate,
  separator: "-",
  digits: {2, 2},
  padding: %{char: "!", before: 1, after: 1, to_length: 0},
  substitutions: %{"a" => "@", "e" => "3"},
  substitution_mode: :always
)
```

Word counts are 1–10; counts below three are intended for constrained or
experimental configurations. Digit counts are 0–5 on each side. Default word
length bounds are 4–10; non-Latin dictionaries can set `word_length_bounds`.
Substitution keys are lowercase graphemes. Case transformation runs first,
then configured substitutions, then `meta.transforms`.

## Presets

- `:default`: three words with alternating case, digits, and symbols.
- `:xkcd`: five words with randomized upper/lowercase and hyphen separators.
- `:web32`: fits a 32-character limit.
- `:web16`: constrained compatibility fallback with substantially lower entropy.
- `:wifi`: exactly 63 printable ASCII characters.
- `:apple_id`: includes upper/lowercase letters and digits.
- `:security`: random words for an invented security-question answer.

```elixir
ExkPasswd.Config.Presets.get(:xkcd)
ExkPasswd.Config.Presets.list()
ExkPasswd.Config.Presets.all() # Built-in configurations only
```

Built-ins work without a process. Runtime registration requires adding
`{ExkPasswd.Config.Presets, []}` to the application's supervision tree.
Built-ins take precedence over runtime entries with the same name; use a new
name when registering a custom preset.

## Custom dictionaries and transforms

Load dictionaries once during provisioning/startup. Custom dictionaries use
`:persistent_term`; frequent replacement can impose garbage-collection work
across the VM. Names must be existing application-controlled atoms. Never
convert untrusted input with `String.to_atom/1`.

```elixir
ExkPasswd.Dictionary.load_custom(:spanish, ["casa", "perro", "gato", "libro"])
config = ExkPasswd.Config.new!(dictionary: :spanish, num_words: 4)
ExkPasswd.generate(config)
ExkPasswd.Dictionary.delete_custom(:spanish)
```

This small dictionary is an API example, not a suitable production word pool.
Words must be nonempty UTF-8 strings and unique after NFC normalization. Case
variants deduplicate outputs and filter by their transformed lengths.

Built-in transforms include `CaseTransform`, `Substitution`, `Pinyin`, and
`Romaji` under `ExkPasswd.Transform`:

```elixir
config = ExkPasswd.Config.new!(meta: %{transforms: [
  %ExkPasswd.Transform.Substitution{map: %{"e" => "3"}, mode: :always}
]})
ExkPasswd.generate(config)
```

Custom transforms implement `apply/3` and `entropy_bits/2`. Define them under
`lib/` before protocol consolidation. Return valid UTF-8 strings; deterministic
transforms must depend only on their arguments. Return `0.0` nominal bits for
deterministic transforms, which can still reduce entropy through collisions.
See the protocol documentation for a complete implementation example.

## Entropy and security

```elixir
password = ExkPasswd.generate(config)
report = ExkPasswd.calculate_entropy(password, config)
report.seen
ExkPasswd.analyze_strength(password, config)
ExkPasswd.strength_rating(password, config)
```

Analyze only with the configuration that generated the password. This is not a
strength estimator for arbitrary user-chosen passwords.

`seen` is a conservative generator-aware min-entropy estimate. Always use the
reported total: `details.composition_loss` deducts potential collisions during
assembly. `blind` is a character-class search-space heuristic. Unknown random
custom transforms receive a zero seen estimate. Ratings are project-defined
bands, not NIST or OWASP certifications. See `docs/SECURITY.md` for assumptions.

All random password choices must use `:crypto.strong_rand_bytes/1` and unbiased
rejection sampling. Use `ExkPasswd.Random.integer/1` for bounded integers.
Never use `:rand`, `Enum.random/1`, timestamps, or user-provided seeds.
Do not log generated words, random buffers, or passwords.

## Validation and performance

Use `Config.new/1` for tagged validation errors and `Config.new!/1` when invalid
configuration should raise `ArgumentError`. Generation validates Config structs
again, including manually constructed or modified structs.

Prefer explicit Config values over application-global generation settings.
Batch APIs buffer word/digit randomness; some other choices still call the
cryptographic source directly. Measure throughput on the target runtime and
hardware before selecting buffered or parallel generation. Neither is
universally faster than a loop.

## Verification

Run `mix check` before considering a change complete. It includes compilation,
formatting, strict Credo, dependency audits, Dialyzer, Doctor, documentation,
package regression tests, and the 95% coverage floor. Statistical smoke tests
can catch gross defects; they do not prove cryptographic security.
