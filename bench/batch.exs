# Benchmark batch password generation vs individual generation
#
# Run with: mix bench.batch
#
# Compares the performance of generating multiple passwords at once
# using batch generation (with buffered random) vs generating them
# individually in a loop.

alias ExkPasswd.{Batch, Config}

# Ensure compiled
Mix.Task.run("compile")

# CI mode: fast verification (benchmarks compile and run)
# Local mode: full benchmarks for accurate performance measurement
{time, warmup, memory_time, counts} =
  if System.get_env("CI") do
    {0.5, 0.1, 0.1, [10, 100]}
  else
    {5, 2, 2, [100, 1000, 10_000]}
  end

# Test settings for benchmarking
settings = Config.Presets.get(:default)

# Generate benchmark scenarios
scenarios =
  for count <- counts, into: %{} do
    {"batch #{count} passwords", fn ->
      Batch.generate_batch(count, settings)
    end}
  end
  |> Map.merge(
    for count <- counts, into: %{} do
      {"individual #{count} passwords", fn ->
        for _ <- 1..count do
          ExkPasswd.generate(settings)
        end
      end}
    end
  )

Benchee.run(
  scenarios,
  time: time,
  memory_time: memory_time,
  warmup: warmup,
  formatters: [
    Benchee.Formatters.Console
  ],
  print: [
    benchmarking: true,
    fast_warning: false,
    configuration: true
  ]
)

IO.puts("\n")
IO.puts("=== Batch Generation Analysis ===")
IO.puts("Batch generation uses buffered random bytes for improved performance.")
IO.puts("Expected speedup: 1.5-3x for large batches (1000+ passwords)")
IO.puts("")
IO.puts("Key insight: Reducing :crypto.strong_rand_bytes/1 calls")
IO.puts("significantly improves throughput for bulk generation.")
