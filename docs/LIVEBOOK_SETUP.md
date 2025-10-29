# Livebook & Benchmarking

ExkPasswd provides interactive Livebook notebooks for learning, experimentation, and performance analysis.

## What is Livebook?

[Livebook](https://livebook.dev/) is an interactive notebook platform for Elixir. Think Jupyter notebooks, but native to Elixir with live code execution, visualizations, and collaborative features.

## Available Notebooks

ExkPasswd includes five interactive notebooks:

### 📘 [Quick Start](notebooks/quickstart.livemd)

Get started with ExkPasswd basics:
- Generate passwords with presets
- Create custom configurations
- Batch generation
- Strength analysis

**For:** New users and quick reference

### 📗 [Advanced Usage](notebooks/advanced.livemd)

Deep dive into advanced features:
- Fine-grained configuration control
- Character substitutions (leetspeak)
- Custom dictionaries and internationalization
- Transform protocol usage

**For:** Users building custom password policies

### 📕 [Security Analysis](notebooks/security.livemd)

Understand password security:
- Entropy calculations explained
- Strength ratings and crack time estimates
- Preset security comparisons
- Cryptographic randomness verification

**For:** Security-conscious users and auditors

### 📊 [Benchmarks](notebooks/benchmarks.livemd)

Performance metrics and analysis:
- Password generation speed
- Dictionary O(1) lookup verification
- Batch vs individual generation comparison
- Memory usage analysis

**For:** Performance optimization and verification

### 🛠️ [Contributing Guide](notebooks/contributing.livemd)

Interactive developer onboarding:
- Architecture exploration with live code
- Test changes without running full test suite
- Create custom presets and transforms
- Performance testing your changes

**For:** Contributors and developers

## Running Notebooks

### Option 1: Run in Browser (Easiest)

Click any "Run in Livebook" badge in the README or notebook files to run directly in your browser without installation.

### Option 2: Local Livebook

1. **Install Livebook:**
   ```bash
   mix escript.install hex livebook
   ```

2. **Start Livebook server:**
   ```bash
   livebook server
   ```

3. **Open a notebook:**
   - Navigate to the ExkPasswd directory
   - Open any `.livemd` file from `notebooks/`

### Option 3: Livebook Desktop

Download [Livebook Desktop](https://livebook.dev/#install) for a native app experience.

## Benchmarks

ExkPasswd includes standalone benchmark scripts for CI/automation:

### Running Benchmarks

```bash
# All benchmarks
mix bench.all

# Individual benchmarks
mix bench.password  # Password generation performance
mix bench.dict      # Dictionary operation performance
mix bench.batch     # Batch generation performance
```

### Benchmark Scripts

- **`bench/password_generation.exs`** - Core generation, presets, transforms
- **`bench/dictionary.exs`** - Dictionary operations (O(1) verification)
- **`bench/batch.exs`** - Batch vs individual generation comparison

### CI vs Local Mode

Benchmarks automatically adapt to their environment:

**CI Mode (when `CI=true`):**
- Fast verification (~30 seconds total)
- Verifies benchmarks compile and run
- Shorter durations: `time: 0.5s, warmup: 0.1s`
- Smaller batch sizes: `[10, 100]`

**Local Mode (default):**
- Accurate performance measurement (~5+ minutes)
- Full benchmark durations: `time: 5s, warmup: 2s`
- Large batch sizes: `[100, 1000, 10_000]`

**Running in CI mode locally:**
```bash
CI=true mix bench.all
```

## Why Two Approaches?

**Livebook Notebooks (Interactive)**
- Learn by doing with live code execution
- Experiment with configurations safely
- Run on your own hardware for accurate results
- Great for exploration and education

**Benchmark Scripts (Automation)**
- Run in CI to catch API breaking changes
- Fast verification without performance measurement
- Scripted for automation and regression testing
- No GUI required

## CI Integration

Benchmarks run automatically in GitHub Actions on every push and pull request via `.github/workflows/benchmarks.yml`.

**Purpose:** Verify benchmarks compile and run successfully, catching API breaking changes that would break benchmark code.

**Not for:** Performance regression detection (too noisy on CI hardware).

## Performance Characteristics

ExkPasswd is optimized for speed:

- **Dictionary lookups:** O(1) via tuple-based indexing
- **Case transforms:** Pre-computed variants (3x faster)
- **Batch generation:** Buffered random bytes (1.5-3x faster for large batches)
- **Custom dictionaries:** ETS-backed for O(1) lookups

Benchmarks verify these characteristics remain true as the codebase evolves.

## Resources

- [Livebook Documentation](https://livebook.dev/)
- [Benchee Documentation](https://hexdocs.pm/benchee)
- [ExkPasswd Documentation](https://hexdocs.pm/exk_passwd)
- [Contributing Guide](CONTRIBUTING.md)
