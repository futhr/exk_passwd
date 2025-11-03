# ExkPasswd Agent Guidelines

This document provides context and rules for autonomous agents working on ExkPasswd.

## Project Overview

ExkPasswd is an Elixir library for generating secure, memorable passwords using the XKPasswd concept. It combines random words with numbers, symbols, and transformations to create strong yet easy-to-remember passwords.

**Key Principles:**
- Security first: Always use cryptographically secure randomness
- Simplicity: Keep the API clean and intuitive
- Zero dependencies: Use only Elixir stdlib and :crypto
- Well-tested: Maintain >90% test coverage
- Well-documented: All public APIs must have comprehensive docs

## Code Quality Standards

### Formatting and Linting

Always run after making changes:
```bash
mix format
mix credo --strict
```

### Testing

Run tests before marking any task complete:
```bash
mix test
mix coveralls.html  # Check coverage
```

### Type Specifications

All public functions MUST have @spec:
```elixir
@spec generate() :: String.t()
@spec generate(atom() | String.t() | Config.t()) :: String.t()
```

### Documentation

All public modules and functions MUST have:
- `@moduledoc` with description and examples
- `@doc` with parameters, return values, and examples
- Doctests where applicable

## Elixir Best Practices

### Pattern Matching

Prefer pattern matching over conditionals:
```elixir
# Good
def generate(%Config{} = config), do: create(config)
def generate(preset) when is_atom(preset), do: ...

# Avoid
def generate(input) do
  if is_struct(input, Config) do
    ...
  end
end
```

### Pipelines

Use pipelines for data transformation:
```elixir
# Good
words
|> Enum.map(&transform/1)
|> Enum.join(separator)
|> add_padding()

# Avoid
add_padding(Enum.join(Enum.map(words, &transform/1), separator))
```

### Function Size

Keep functions small and focused (<20 lines ideally):
```elixir
# Good - Single responsibility
def generate_password(settings) do
  settings
  |> select_words()
  |> transform_case()
  |> join_with_separator()
  |> add_padding()
end

# Avoid - Too much in one function
def generate_password(settings) do
  # 50+ lines of mixed concerns
end
```

### Error Handling

Use tagged tuples for expected errors:
```elixir
# Good
def validate(settings) do
  cond do
    settings.num_words < 1 -> {:error, "num_words must be at least 1"}
    true -> {:ok, settings}
  end
end

# For internal errors, let it crash
def select_word!([]), do: raise "Empty word list"
```

## Security Requirements

### Critical: Use Cryptographic Random

**NEVER use `:rand` module or `Enum.random/1`**

```elixir
# REQUIRED - Cryptographically secure
:crypto.strong_rand_bytes(4) |> :binary.decode_unsigned()

# FORBIDDEN - Predictable, insecure
:rand.uniform(100)
Enum.random(list)
```

### Word Selection

Ensure uniform distribution:
```elixir
def random_index(count) when count > 0 do
  :crypto.strong_rand_bytes(4)
  |> :binary.decode_unsigned()
  |> rem(count)
end
```

### Password Generation

- Minimum 3 words for basic security
- Use configurable separators and padding
- Avoid common/weak words in dictionary
- No hardcoded passwords or keys in code/tests

## Module Organization

```
lib/
├── exk_passwd.ex              # Main API
├── exk_passwd/
│   ├── settings.ex            # Configuration struct
│   ├── presets.ex             # Preset configurations
│   ├── password_creator.ex    # Core generation logic
│   ├── dictionary.ex          # Word list management
│   ├── transformer.ex         # Case/padding transforms
│   ├── random.ex              # Secure random utilities
│   └── cli.ex                 # Command-line interface
```

### Module Responsibilities

- **ExkPasswd**: Public API only, delegate to other modules
- **Config**: Configuration struct and validation
- **Presets**: Immutable preset configurations (use module attributes)
- **PasswordCreator**: Core generation orchestration
- **Dictionary**: Word loading and selection
- **Transformer**: Case transforms, padding, separators
- **Random**: Cryptographically secure random utilities
- **CLI**: Command-line interface (escript entry point)

## Testing Guidelines

### Unit Tests

Test all public functions with multiple cases:
```elixir
describe "generate/1" do
  test "generates password with default settings" do
    password = ExkPasswd.generate()
    assert is_binary(password)
    assert String.length(password) > 0
  end

  test "generates password with preset atom" do
    password = ExkPasswd.generate(:xkcd)
    assert password =~ ~r/\w+-\w+-\w+/
  end

  test "generates password with preset string" do
    password = ExkPasswd.generate("wifi")
    assert String.length(password) <= 63
  end

  test "generates password with custom config" do
    config = ExkPasswd.Config.new!(num_words: 2, separator: "_")
    password = ExkPasswd.generate(config)
    assert password =~ ~r/\w+_\w+/
  end

  test "returns different passwords each time" do
    passwords = for _ <- 1..10, do: ExkPasswd.generate()
    assert length(Enum.uniq(passwords)) == 10
  end
end
```

### Property-Based Tests

Use StreamData for property testing:
```elixir
property "generated passwords have correct number of words" do
  check all num_words <- integer(2..6) do
    config = ExkPasswd.Config.new!(num_words: num_words, separator: "-")
    password = ExkPasswd.generate(config)
    word_count = password |> String.split("-") |> length()
    assert word_count == num_words
  end
end
```

### Security Tests

Test randomness and uniqueness:
```elixir
test "generates unique passwords" do
  passwords = for _ <- 1..1000, do: ExkPasswd.generate()
  unique_count = passwords |> Enum.uniq() |> length()
  # Allow tiny collision chance but should be near 1000
  assert unique_count > 995
end

test "no passwords contain weak patterns" do
  forbidden = ["password", "admin", "12345", "qwerty"]

  for _ <- 1..100 do
    password = ExkPasswd.generate() |> String.downcase()
    for pattern <- forbidden do
      refute String.contains?(password, pattern)
    end
  end
end
```

### Coverage Goals

- Maintain >90% overall coverage
- 100% coverage for security-critical code (Random, Dictionary selection)
- All public API functions must be tested

## Documentation Standards

### Module Documentation

```elixir
defmodule ExkPasswd.Something do
  @moduledoc """
  Brief description of module purpose.

  Longer explanation with context if needed.

  ## Examples

      iex> ExkPasswd.Something.function()
      "result"
  """
end
```

### Function Documentation

```elixir
@doc """
Brief one-line description.

More detailed explanation if needed, including:
- When to use this function
- Important behavior notes
- Edge cases

## Parameters

- `param1` - Description with type info
- `param2` - Description with valid values

## Returns

Description of return value and possible values.

## Examples

    iex> function(arg1, arg2)
    expected_result

    iex> function(invalid)
    ** (ArgumentError) error message
"""
@spec function(type1, type2) :: return_type
def function(param1, param2) do
  # implementation
end
```

### Doctests

Use doctests where practical:
```elixir
@doc """
Generates a password.

## Examples

    iex> password = ExkPasswd.generate()
    iex> is_binary(password)
    true
    iex> String.length(password) > 0
    true
"""
```

## Git Workflow

### Commit Messages

Follow conventional commits:
```
feat: add passphrase generation
fix: correct word selection bias
docs: update API examples
test: add property tests for transformers
refactor: simplify password creator logic
perf: optimize dictionary loading
```

### Before Committing

1. Run `mix format`
2. Run `mix credo --strict`
3. Run `mix test`
4. Update CHANGELOG.md if user-facing change

## Performance Considerations

### Dictionary Loading

Load once, reuse:
```elixir
# Good - Load at compile time or startup
@words File.read!("priv/words.txt") |> String.split("\n")

def random_word, do: @words |> secure_random_select()

# Avoid - Loading on every call
def random_word do
  File.read!("priv/words.txt") |> String.split("\n") |> ...
end
```

### String Building

Use efficient methods:
```elixir
# Good
Enum.join(words, separator)
IO.iodata_to_binary([prefix, words, suffix])

# Avoid
Enum.reduce(words, "", fn w, acc -> acc <> w <> sep end)
```

### Presets

Use compile-time constants:
```elixir
# Good - Computed at compile time
@presets %{
  "default" => Config.new!(...),
  "wifi" => Config.new!(...)
}

def get(name), do: Map.get(@presets, name)

# Avoid - Rebuilding on every call
def get(name) do
  presets = %{"default" => Config.new!(...), ...}
  Map.get(presets, name)
end
```

## Common Patterns

### Configuration Validation

```elixir
defmodule ExkPasswd.Config do
  defstruct [...]

  def new!(opts) do
    config = struct(__MODULE__, opts)

    case ExkPasswd.Config.Schema.validate(config) do
      :ok -> config
      {:error, reason} -> raise ArgumentError, reason
    end
  end

  def new(opts) do
    config = struct(__MODULE__, opts)

    case ExkPasswd.Config.Schema.validate(config) do
      :ok -> {:ok, config}
      {:error, _} = error -> error
    end
  end
end
```

### Case Transformations

```elixir
def transform_case(word, :capitalize), do: String.capitalize(word)
def transform_case(word, :upper), do: String.upcase(word)
def transform_case(word, :lower), do: String.downcase(word)
def transform_case(word, :none), do: word
def transform_case(word, :random) do
  if secure_random_boolean(), do: String.upcase(word), else: String.downcase(word)
end
```

### Preset Definitions

```elixir
@presets %{
  default: Config.new!(
    num_words: 3,
    separator: "-",
    case_transform: :random,
    word_length: 4..8,
    digits: {2, 2}
  ),
  xkcd: Config.new!(
    num_words: 4,
    separator: "-",
    case_transform: :lower,
    word_length: 4..8,
    digits: {0, 0},
    padding: %{before: 0, after: 0}
  ),
  # ... more presets
}
```

## CLI Development

If building CLI functionality:

### Escript Configuration

In mix.exs:
```elixir
escript: [main_module: ExkPasswd.CLI]
```

### CLI Module

```elixir
defmodule ExkPasswd.CLI do
  def main(args) do
    args
    |> parse_args()
    |> execute()
    |> output()
  end

  defp parse_args(args) do
    {opts, _, _} = OptionParser.parse(args,
      switches: [
        preset: :string,
        words: :integer,
        separator: :string,
        count: :integer,
        help: :boolean
      ],
      aliases: [p: :preset, w: :words, s: :separator, c: :count, h: :help]
    )
    opts
  end
end
```

### CLI Features

Support these options:
- `--preset <name>` or `-p <name>`: Use preset
- `--words <n>` or `-w <n>`: Number of words
- `--separator <char>` or `-s <char>`: Separator character
- `--count <n>` or `-c <n>`: Generate N passwords
- `--help` or `-h`: Show help
- `--version` or `-v`: Show version

## Dependencies

Keep dependencies minimal:

### Allowed (only if necessary)
- No runtime dependencies currently
- Dev/test only: credo, dialyxir, ex_doc, excoveralls, mix_test_watch

### Avoid
- Don't add external dependencies without strong justification
- Use Elixir stdlib and :crypto for all core functionality

## Release Checklist

Before releasing a new version:

1. Update version in mix.exs
2. Update CHANGELOG.md
3. Run full test suite: `mix test`
4. Run dialyzer: `mix dialyzer`
5. Generate docs: `mix docs` and review
6. Build escript: `mix escript.build` and test
7. Create git tag: `git tag v0.x.x`
8. Publish to Hex: `mix hex.publish`

## Error Messages

Make error messages helpful:

```elixir
# Good - Clear, actionable
{:error, "num_words must be at least 1, got: #{n}"}
{:error, "word_length_min (#{min}) must be <= word_length_max (#{max})"}

# Avoid - Vague
{:error, "invalid settings"}
```

## Debugging

Use Logger for development debugging:
```elixir
require Logger
Logger.debug("Selected word: #{word}, length: #{String.length(word)}")
```

Remove debug logs before committing.

## Questions and Clarifications

When uncertain:
- Consult OWASP password guidelines
- Reference NIST Digital Identity Guidelines
- Check XKPasswd documentation for inspiration
- Ask user for clarification on security decisions

## Remember

- Security is paramount - never compromise on cryptographic quality
- Keep it simple - resist feature creep
- Document everything - others will use this library
- Test thoroughly - passwords are security-critical
- Performance matters - but not at cost of security or clarity

---

**When in doubt, prioritize security over convenience.**
