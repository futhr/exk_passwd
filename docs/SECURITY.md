# Security model

ExkPasswd generates passwords from independently selected words and tokens. Its
security assumptions are deliberately public: an attacker may know the library,
dictionary, preset, and every configuration value except the random choices.

## Randomness

All random choices ultimately use `:crypto.strong_rand_bytes/1`. Integer ranges
use rejection sampling, including buffered batch generation, so reducing a byte
value modulo a non-power-of-two range does not bias some outcomes.

The generator never uses `:rand`, `Enum.random/1`, timestamps, process IDs, or a
user-provided seed for password material.

This guarantees use of the Erlang/OTP cryptographic random source and unbiased
range reduction. It does not guarantee that a host with a compromised operating
system, runtime, or hardware random source remains secure.

## Bundled dictionary

`priv/dict/eff_large.txt` is derived from the EFF Large Wordlist. Four entries
containing hyphens are omitted so a hyphen can be used as a separator without
making word boundaries ambiguous:

- `drop-down`
- `felt-tip`
- `t-shirt`
- `yo-yo`

The resulting file contains 7,772 lowercase ASCII words. Its SHA-256 digest is:

```text
18586c092f641ecd1a471dd6ab35618ab69f0aa7483486424f7caf0996d06259
```

Verify it with:

```bash
shasum -a 256 priv/dict/eff_large.txt
```

Selecting from all 7,772 entries would provide `log2(7772) ≈ 12.92` bits per
word. Presets restrict word length, so their effective pool can be smaller; use
`ExkPasswd.Entropy.calculate_seen/1` for a configuration-specific estimate.

The bundled list is convenient provisioning. Applications may load any suitable
dictionary with `ExkPasswd.Dictionary.load_custom/2`. Custom words are normalized
to NFC, duplicates are rejected, and case-output duplicates are stored once.
Dictionary authors remain responsible for language coverage, offensive content,
memorability, and resource usage.

## Entropy calculation

`seen` entropy assumes the attacker knows the generator. It is a conservative
lower bound on min-entropy, not a sum of complexity points. The model:

- counts only dictionary entries in the configured length range;
- accounts for collisions caused by case conversion and substitutions;
- accounts for deterministic Pinyin and Romaji collisions;
- credits random casing or substitution only when it creates distinct outputs;
- gives unverifiable random custom transforms no entropy credit;
- counts repeated separator/padding characters according to their probabilities;
- gives unused separators no credit;
- subtracts a composition deduction when word boundaries cannot be established.

ASCII letter words with punctuation separators have recoverable component
boundaries. For other layouts, the model groups each word distribution by byte
length and sums the maximum probability in each group. The product of these
sums bounds the probability of a composed output once separator and padding
choices are fixed. The bound retains fixed-width digit entropy and removes
symbol-choice credit. This avoids assuming that different word tuples always
produce different strings, at the cost of pessimistic estimates for some valid
configurations. `details.composition_loss` records the deduction; use `total`,
not the unadjusted sum of component fields.

For example, two words from `["aaaa", "aaaaaaaa"]` without a separator have
only three outputs, with probabilities 1/4, 1/2, and 1/4. Their min-entropy is
1 bit, not 2. The conservative bound may be lower still.

Unknown random transforms and unavailable word pools receive a zero total.
Custom deterministic transforms must be pure functions of their arguments.

Minimum-length padding receives no entropy credit because some generated values
may already meet the minimum and receive no padding. This is conservative.

`blind` is a character-class brute-force search-space heuristic. It is useful for
contrasting naive brute force with a generator-aware attack, but it is not the
entropy of an observed string.

Crack-time text assumes one billion guesses per second and an average search of
half the candidate space. Actual rates vary enormously with online throttling,
MFA, password hashing, attacker hardware, and breach conditions.

## Transform caveats

Romanization is often many-to-one. For example, the supplied toneless Pinyin
mapping converts both `是` and `事` to `shi`. A deterministic transform therefore
adds no randomness and can reduce the output space. The entropy calculator
enumerates built-in deterministic outputs to capture those collisions.

Pinyin is character-based and does not disambiguate context-dependent readings.
Romaji supports kana, not Kanji morphological analysis. Unmapped characters pass
through unchanged. Validate every custom language dictionary if the destination
requires ASCII:

```elixir
transform = %ExkPasswd.Transform.Pinyin{}

unmapped =
  Enum.filter(words, fn word ->
    ExkPasswd.Transform.apply(transform, word, nil) =~ ~r/[^a-z]/
  end)
```

## Output length

`padding.to_length` sets a minimum. ExkPasswd never truncates a generated
password to meet a smaller limit, because truncation can discard entire random
components and invalidate entropy estimates. Choose a configuration whose
maximum natural length fits the destination instead.

The `web16`, `web32`, and `wifi` presets are constructed so their natural maxima
fit their advertised limits. The Wi-Fi preset emits 63 printable ASCII
characters, the passphrase maximum accepted by WPA/WPA2-Personal tooling. A
64-character hexadecimal value represents a raw PSK rather than a 64-character
passphrase.

## What this library does not solve

Password generation is only one part of authentication security. ExkPasswd does
not:

- check generated or user-supplied values against breach blocklists;
- store, hash, transmit, rotate, or synchronize passwords;
- protect against phishing, keylogging, clipboard monitoring, or endpoint
  compromise;
- provide rate limiting or multi-factor authentication;
- assess whether a destination silently normalizes or truncates input.

Use a modern password manager and a memory-hard password hash where applicable.
Enable MFA for important accounts. Test the exact password field before relying
on Unicode, whitespace, or uncommon punctuation.

## Current guidance

NIST SP 800-63B emphasizes password length, blocklists, rate limiting, and
allowing long passphrases. It advises verifiers not to impose composition rules
on user-chosen passwords. OWASP likewise recommends long-password support and
explicitly says not to silently truncate passwords.

These are verifier guidelines, not entropy thresholds for this library. The
rating bands returned by ExkPasswd are project-defined convenience labels.

- [NIST SP 800-63B](https://pages.nist.gov/800-63-4/sp800-63b.html)
- [OWASP Authentication Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html)
- [OWASP Password Storage Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html)
- [EFF random-passphrase wordlists](https://www.eff.org/deeplinks/2016/07/new-wordlists-random-passphrases)

## Verification

Run the security-focused tests and normal quality gates with:

```bash
mix check
```

Statistical tests are regression smoke tests. Passing them does not prove that a
random-number generator is cryptographically secure; that property comes from
the reviewed use of `:crypto.strong_rand_bytes/1` and unbiased sampling.

## Reporting a vulnerability

Please use GitHub's private security-advisory flow for the repository. Include a
minimal reproducer, affected versions, expected impact, and any suggested
mitigation. Avoid publishing exploitable details before a fix is available.
