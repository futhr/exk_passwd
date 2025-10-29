# Contributing to ExkPasswd

Thank you for considering contributing to ExkPasswd! This document provides guidelines and information to help you get started.

---

## Interactive Developer Guide

We've created an **interactive Livebook notebook** to help you understand the codebase and experiment with changes in real-time:

[![Run in Livebook](https://livebook.dev/badge/v1/blue.svg)](https://livebook.dev/run?url=https%3A%2F%2Fgithub.com%2Ffuthr%2Fexk_passwd%2Fblob%2Fmain%2Fnotebooks%2Fcontributing.livemd)

**Why use the interactive notebook?**

* **Immediate feedback** - Test your changes without running the full test suite
* **Explore architecture** - See how Dictionary, Password, Config, and Transforms work together
* **Run examples live** - Execute code while reading documentation
* **Safe experimentation** - Try ideas without modifying the actual codebase
* **Performance testing** - Verify O(1) lookups and benchmark your changes

The notebook covers:
- Project structure and architecture
- Key design patterns (schema-driven config, Transform protocol, O(1) lookups)
- Security verification (cryptographic randomness, entropy analysis)
- Creating custom presets and transforms
- Testing edge cases
- Performance benchmarking

---

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible:

* **Use a clear and descriptive title**
* **Describe the exact steps to reproduce the problem**
* **Provide specific examples to demonstrate the steps**
* **Describe the behavior you observed and what behavior you expected**
* **Include your environment details** (Elixir version, OS, etc.)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

* **Use a clear and descriptive title**
* **Provide a detailed description of the suggested enhancement**
* **Provide specific examples to demonstrate the enhancement**
* **Describe the current behavior and expected behavior**
* **Explain why this enhancement would be useful**

### Pull Requests

1. Fork the repo and create your branch from `main`
2. Add tests for any new functionality
3. Ensure the test suite passes (`mix test`)
4. Make sure your code follows the style guidelines (`mix format` and `mix credo`)
5. Write clear, descriptive commit messages
6. Issue that pull request!

## Development Setup

1. **Fork and clone the repository**
   ```bash
   git clone https://github.com/futhr/exk_passwd.git
   cd exk_passwd
   ```

2. **Install dependencies**
   ```bash
   mix deps.get
   ```

3. **Run tests to ensure everything is working**
   ```bash
   mix test
   ```

## Development Workflow

### Running Tests

```bash
# Run all tests
mix test

# Run tests with coverage
mix coveralls.html

# Run tests in watch mode
mix test.watch

# Run specific test file
mix test test/exk_passwd/generator_test.exs
```

### Code Quality

```bash
# Format code
mix format

# Run Credo for style consistency
mix credo --strict

# Run Dialyzer for type checking
mix dialyzer

# Run all checks
mix check
```

### Building Documentation

```bash
# Generate docs
mix docs

# View docs
open doc/index.html
```

## Project Structure

```
lib/exk_passwd/
├── config/               # Configuration system
│   ├── presets.ex       # Built-in presets (Agent-based)
│   └── schema.ex        # Configuration validation
├── transform/            # Transform protocol implementations
│   ├── case_transform.ex
│   └── substitution.ex
├── config.ex            # Configuration struct (schema-driven)
├── dictionary.ex        # ETS-backed word storage (O(1) lookups)
├── password.ex          # Core password generation engine
├── batch.ex             # Optimized batch generation
├── token.ex             # Random number/symbol generation
├── buffer.ex            # Buffered random bytes for performance
├── entropy.ex           # Entropy calculation
├── strength.ex          # Password strength analysis
├── transform.ex         # Transform protocol definition
├── validator.ex         # Configuration validation
└── random.ex            # Cryptographically secure random utilities
```

## Testing Guidelines

### Writing Tests

* Write tests for all public functions
* Include both success and error cases
* Use descriptive test names
* Aim for >90% test coverage (100% for security-critical code)
* Test randomness and uniqueness for password generation

Example test structure:

```elixir
describe "generate/1" do
  test "generates password with default settings" do
    password = ExkPasswd.generate()
    assert is_binary(password)
    assert String.length(password) > 0
  end

  test "generates different passwords each time" do
    passwords = for _ <- 1..10, do: ExkPasswd.generate()
    assert length(Enum.uniq(passwords)) == 10
  end

  test "generates unique passwords at scale" do
    passwords = for _ <- 1..1000, do: ExkPasswd.generate()
    unique_count = passwords |> Enum.uniq() |> length()
    # Allow tiny collision chance
    assert unique_count > 995
  end
end
```

## Coding Style

### Elixir Style Guide

* Use pattern matching over conditionals when possible
* Keep functions under 20 lines
* Use descriptive variable and function names
* Write comprehensive `@moduledoc` and `@doc` documentation
* Include doctests in documentation
* Prefer pipelines over nested calls

### Commit Messages

We follow conventional commits:

* `feat:` New feature
* `fix:` Bug fix
* `docs:` Documentation changes
* `style:` Formatting, missing semicolons, etc.
* `refactor:` Code restructuring
* `test:` Adding tests
* `chore:` Maintenance tasks

Examples:
```
feat: add passphrase generation
fix: handle edge case in strength checker
docs: update README with examples
test: add integration tests for validator
```

## Project Principles

ExkPasswd follows these core principles:

### 1. Security First
- **Always use cryptographically secure randomness** (`:crypto.strong_rand_bytes/1`)
- **Never use** `Enum.random/1` or `:rand` module for password generation
- Test randomness and uniqueness thoroughly

### 2. Zero Runtime Dependencies
- Only use Elixir stdlib and `:crypto`
- Dev/test dependencies are acceptable
- No external dependencies for core functionality

### 3. Well-Tested
- Maintain >90% overall test coverage
- 100% coverage for security-critical code
- All public API functions must be tested

### 4. Performance Matters
- Dictionary uses O(1) lookups (tuple-based)
- Batch generation uses buffered random bytes
- Run benchmarks to verify performance

## Documentation

* All public modules must have `@moduledoc`
* All public functions must have `@doc` with examples
* Include doctests where appropriate
* Update README.md for user-facing changes
* Update CHANGELOG.md following Keep a Changelog format

## Release Process

1. Update version in `mix.exs`
2. Update CHANGELOG.md
3. Run all tests and checks
4. Create a pull request
5. After merge, tag the release
6. Publish to Hex.pm

## Resources

### Documentation
- [README](README.md) - Project overview
- CLAUDE.md (in repository root) - Agent guidelines and best practices
- [Hex Docs](https://hexdocs.pm/exk_passwd) - Published documentation

### Interactive Notebooks
- [Quick Start](notebooks/quickstart.livemd) - Basic usage
- [Advanced Usage](notebooks/advanced.livemd) - Custom configurations
- [Security Analysis](notebooks/security.livemd) - Entropy and strength
- [Benchmarks](notebooks/benchmarks.livemd) - Performance testing
- [Contributing](notebooks/contributing.livemd) - **Interactive developer guide**

### References
- [EFF Large Wordlist](https://www.eff.org/deeplinks/2016/07/new-wordlists-random-passphrases)
- [Original Perl Implementation](https://github.com/bbusschots/hsxkpasswd)
- [XKCD Comic #936](https://xkcd.com/936/)

---

## Questions?

- Open an issue on GitHub
- Check existing issues and discussions
- Review the interactive contributing notebook

**Thank you for contributing to ExkPasswd!** 🎉
