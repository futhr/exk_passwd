# ExkPasswd Usage Rules for AI Agents

This document provides condensed guidance for AI agents working with ExkPasswd, an Elixir password generation library based on the XKPasswd concept.

## Core Principles

1. **Security First**: Always use cryptographically secure randomness via `:crypto.strong_rand_bytes/1`
2. **Zero Dependencies**: Library uses only Elixir stdlib and `:crypto` module
3. **Explicit Configuration**: Use Config structs, not application config
4. **EFF Wordlist**: Uses 7,826-word EFF Large Wordlist for high entropy (12.9 bits/word)

## Primary API Functions

### Basic Password Generation

```elixir
# Default settings
ExkPasswd.generate()
#=> "45?clever?FOREST?mountain?89"

# Use preset (atom or string)
ExkPasswd.generate(:xkcd)
#=> "correct-horse-battery-staple-amazing"

# Custom configuration with keyword list
ExkPasswd.generate(num_words: 4, separator: "-", case_transform: :capitalize)
#=> "12-Happy-Forest-Dance-56"

# Custom configuration with Config struct
config = ExkPasswd.Config.new!(
  num_words: 4,
  separator: "-",
  case_transform: :capitalize
)
ExkPasswd.generate(config)
#=> "12-Happy-Forest-Dance-56"

# Extend preset with overrides
ExkPasswd.generate(:xkcd, num_words: 6)
#=> "correct-horse-battery-staple-amazing-forest"
```

### Batch Generation (High Performance)

```elixir
# Generate multiple passwords efficiently
ExkPasswd.generate_batch(100)
ExkPasswd.generate_batch(50, config)

# Ensure uniqueness
ExkPasswd.generate_unique_batch(100)

# Parallel generation (multi-core)
ExkPasswd.generate_parallel(1000)
```

### Entropy and Strength Analysis

```elixir
# Calculate entropy
password = ExkPasswd.generate()
config = ExkPasswd.Config.new!()
ExkPasswd.calculate_entropy(password, config)
#=> %{blind: 125.4, seen: 72.3, status: :good, ...}

# Get strength rating
ExkPasswd.strength_rating(password, config)
#=> :good

# Full strength analysis
ExkPasswd.analyze_strength(password, config)
#=> %{rating: :good, score: 72, entropy_bits: 59.2, ...}
```

## Configuration Patterns

### Config Struct Fields

```elixir
ExkPasswd.Config.new!(
  # Word selection
  num_words: 3,              # Number of words (1-10)
  word_length: 4..8,         # Word length range (4..10)

  # Case transformation
  case_transform: :alternate, # :none | :alternate | :capitalize | :invert | :lower | :upper | :random

  # Separators
  separator: "-",            # Separator string (or random charset)

  # Digits
  digits: {2, 2},            # {before, after} - (0-5 each)

  # Padding
  padding: %{
    char: "!",               # Padding character (or random charset)
    before: 2,               # Padding chars before (0-5)
    after: 2,                # Padding chars after (0-5)
    to_length: 0             # If > 0, pad/truncate to exact length
  },

  # Character substitutions (leetspeak)
  substitutions: %{"a" => "@", "e" => "3"},
  substitution_mode: :none,  # :none | :always | :random

  # Dictionary
  dictionary: :eff,          # :eff or custom atom

  # Metadata for extensions
  meta: %{}
)
```

### Available Presets

```elixir
# Get preset by name
ExkPasswd.Config.Presets.get(:xkcd)
ExkPasswd.Config.Presets.get(:wifi)
ExkPasswd.Config.Presets.get("web32")  # String also works

# Available presets:
# - :default   - Balanced security (~59 bits)
# - :xkcd      - XKCD-style (~65 bits)
# - :wifi      - 63-char WPA2 (~85 bits)
# - :web32     - 32-char limit (~65 bits)
# - :web16     - 16-char limit (~42 bits) ⚠️ LOW SECURITY
# - :apple_id  - Apple ID requirements (~55 bits)
# - :security  - Security questions (~77 bits)

# List all presets
ExkPasswd.Config.Presets.list()
#=> [:default, :xkcd, :wifi, :web32, :web16, :apple_id, :security]

# Get all preset configs
ExkPasswd.Config.Presets.all()
```

### Register Custom Presets

```elixir
# Register a new preset
custom = ExkPasswd.Config.new!(num_words: 8, separator: "_")
ExkPasswd.Config.Presets.register(:super_strong, custom)

# Register by extending existing
ExkPasswd.Config.Presets.register(:strong_wifi, :wifi, num_words: 8, digits: {6, 6})

# Use custom preset
ExkPasswd.generate(:super_strong)
```

## Advanced Features

### Custom Dictionaries

```elixir
# Load custom word list
ExkPasswd.Dictionary.load_custom(:spanish, ["casa", "perro", "gato", "libro"])

# Use custom dictionary
config = ExkPasswd.Config.new!(dictionary: :spanish, num_words: 3)
ExkPasswd.generate(config)
```

### Transform Protocol (Extensibility)

```elixir
# Use built-in substitution transform
config = ExkPasswd.Config.new!(
  num_words: 3,
  meta: %{
    transforms: [
      %ExkPasswd.Transform.Substitution{
        map: %{"a" => "@", "e" => "3", "i" => "!", "o" => "0"},
        mode: :random
      }
    ]
  }
)

ExkPasswd.generate(config)
#=> "45?cl3v3r?FOREST?m0unt@!n?89"

# Create custom transforms
defmodule MyTransform do
  defstruct [:options]

  defimpl ExkPasswd.Transform do
    def apply(%{options: _}, word, _config) do
      # Transform word
      String.reverse(word)
    end

    def entropy_bits(%{options: _}, _config), do: 0.0
  end
end
```

### Dictionary API (Internal Use)

```elixir
# Get random word in length range
ExkPasswd.Dictionary.random_word_between(4, 8)
ExkPasswd.Dictionary.random_word_between(4, 8, :capitalize)
ExkPasswd.Dictionary.random_word_between(4, 8, :upper, :eff)

# Dictionary info
ExkPasswd.Dictionary.size()         #=> 7826
ExkPasswd.Dictionary.min_length()   #=> 3
ExkPasswd.Dictionary.max_length()   #=> 10
ExkPasswd.Dictionary.count_between(4, 8, :eff)
```

## Security Rules

### ✅ ALWAYS Use Cryptographically Secure Random

```elixir
# ✅ Correct - Cryptographically secure
:crypto.strong_rand_bytes(4) |> :binary.decode_unsigned()

# ❌ NEVER DO THIS - Predictable and insecure
:rand.uniform(100)
Enum.random(list)
```

### Password Strength Guidelines

- **Minimum 3 words** for basic security
- **4 words** for good security (~52 bits entropy)
- **5 words** for strong security (~65 bits entropy)
- **6+ words** for excellent security (77+ bits entropy)

### Validation

Config structs are automatically validated. Invalid configurations raise `ArgumentError`:

```elixir
# Invalid settings will raise
ExkPasswd.Config.new!(num_words: 0)
#=> ** (ArgumentError) num_words must be between 1 and 10, got: 0

ExkPasswd.Config.new!(word_length: 10..4)
#=> ** (ArgumentError) word_length range invalid: 10..4 (min must be <= max)

# Safe validation without raising
case ExkPasswd.Config.new(num_words: 0) do
  {:ok, config} -> config
  {:error, msg} -> IO.puts("Invalid: #{msg}")
end
```

## Common Anti-Patterns

### ❌ Don't: Use application config

```elixir
# ❌ Bad - Application-wide config
config :exk_passwd, default_words: 4
```

### ✅ Do: Use Config struct

```elixir
# ✅ Good - Explicit configuration
config = ExkPasswd.Config.new!(num_words: 4)
ExkPasswd.generate(config)
```

### ❌ Don't: Generate passwords in loops

```elixir
# ❌ Bad - Inefficient for many passwords
for _ <- 1..100, do: ExkPasswd.generate()
```

### ✅ Do: Use batch generation

```elixir
# ✅ Good - 30% faster for 100+ passwords
ExkPasswd.generate_batch(100)
ExkPasswd.generate_parallel(1000)  # Multi-core for large batches
```

### ❌ Don't: Manual string concatenation

```elixir
# ❌ Bad - Performance and security issues
words |> Enum.reduce("", fn w, acc -> acc <> w <> "-" end)
```

### ✅ Do: Use the library's built-in generation

```elixir
# ✅ Good - Optimized and secure
ExkPasswd.generate(config)
```

## Error Handling

The library uses "let it crash" philosophy for invalid inputs. Catch `ArgumentError` for validation errors:

```elixir
try do
  config = ExkPasswd.Config.new!(num_words: 0)
  ExkPasswd.generate(config)
rescue
  ArgumentError -> "Invalid configuration"
end
```

## Performance Considerations

### Batch Operations

- Use `generate_batch/2` for 10-100 passwords (~30% faster)
- Use `generate_parallel/2` for 100+ passwords (multi-core scaling)
- Use `generate_unique_batch/2` when uniqueness is required

### Dictionary Loading

Dictionary is loaded at compile-time for zero runtime overhead:
- Words pre-indexed by length
- Case variants pre-computed
- O(1) random word selection via tuple indexing

## Testing Patterns

### Basic Tests

```elixir
test "generates valid password" do
  password = ExkPasswd.generate()
  assert is_binary(password)
  assert String.length(password) > 0
end

test "uses preset correctly" do
  password = ExkPasswd.generate(:xkcd)
  assert password =~ ~r/\w+-\w+-\w+-\w+-\w+/
end

test "uses config correctly" do
  config = ExkPasswd.Config.new!(num_words: 2, separator: "_")
  password = ExkPasswd.generate(config)
  assert password =~ ~r/\w+_\w+/
end
```

### Security Tests

```elixir
test "generates unique passwords" do
  passwords = ExkPasswd.generate_batch(1000)
  unique_count = passwords |> Enum.uniq() |> length()
  assert unique_count > 995  # Allow tiny collision chance
end

test "no weak patterns" do
  for _ <- 1..100 do
    password = ExkPasswd.generate() |> String.downcase()
    refute String.contains?(password, "password")
    refute String.contains?(password, "12345")
  end
end
```

## Module Architecture

```
ExkPasswd (main API)
├── ExkPasswd.Config (configuration struct)
│   ├── ExkPasswd.Config.Presets (preset registry)
│   └── ExkPasswd.Config.Schema (validation)
├── ExkPasswd.Password (core generation)
├── ExkPasswd.Dictionary (word list management)
├── ExkPasswd.Transform (protocol for custom transforms)
│   ├── ExkPasswd.Transform.CaseTransform
│   └── ExkPasswd.Transform.Substitution
├── ExkPasswd.Random (secure random utilities)
├── ExkPasswd.Entropy (entropy calculation)
├── ExkPasswd.Strength (strength analysis)
├── ExkPasswd.Batch (optimized batch generation)
├── ExkPasswd.Buffer (buffered random for performance)
├── ExkPasswd.Token (number/symbol generation)
└── ExkPasswd.Validator (validation behaviour)
```

## Version Requirements

- Elixir >= 1.16
- Erlang OTP >= 26
- No external runtime dependencies

## Documentation

All public functions have comprehensive documentation with examples. Use `h ExkPasswd.generate` in IEx or visit HexDocs for full reference.
