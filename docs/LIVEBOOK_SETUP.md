# Livebook and benchmarks

The repository includes executable examples for learning and local measurement:

- [Quick start](../notebooks/quickstart.livemd)
- [Advanced configuration](../notebooks/advanced.livemd)
- [Security model](../notebooks/security.livemd)
- [Chinese/Pinyin](../notebooks/i18n_chinese.livemd)
- [Japanese/Romaji](../notebooks/i18n_japanese.livemd)
- [Benchmarks](../notebooks/benchmarks.livemd)
- [Contributing](../notebooks/contributing.livemd)

## Run locally

Install or open [Livebook](https://livebook.dev/), then open a `.livemd` file
from the `notebooks` directory. Each user-facing notebook installs the Hex
release it documents. The contributing notebook instead points at the parent
checkout so local edits are visible.

## Benchmark scripts

The command-line Benchee suites are:

```bash
mix bench.password
mix bench.dict
mix bench.batch
mix bench.all
```

Normal mode uses multi-second warmup and measurement windows. `CI=true` selects
short windows and smaller batch sizes so CI can verify that the scripts compile
and run:

```bash
CI=true mix bench.all
```

CI-mode output is a smoke test, not a stable performance measurement. Even full
local results vary with runtime versions, CPU frequency, temperature, scheduler
load, and power settings. Keep that environment metadata with published values.

## Interpreting results

- Common EFF word ranges use precomputed tuples, but uncommon/custom ranges may
  assemble candidates from a by-length index.
- Buffered batch generation reduces crypto calls, but it is not guaranteed to
  outperform individual generation at every batch size.
- Seen-entropy analysis enumerates reachable transformed outputs to find
  collisions and is expected to cost more than one password generation.
- Very short operations can show large relative deviation because timer and
  scheduler noise dominate the measured work.

Regenerate checked-in reports only from a clean checkout after correctness gates
pass. Do not turn one machine's results into a general speedup claim.
