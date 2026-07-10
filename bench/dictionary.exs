# Benchmark dictionary operations
#
# Run with: mix run bench/dictionary.exs
#
# This benchmarks dictionary lookup and filtering operations.

alias ExkPasswd.Dictionary

# Ensure compiled
Mix.Task.run("compile")

# Ensure output directory exists
File.mkdir_p!("bench/output")

# CI mode: fast verification (benchmarks compile and run)
# Local mode: full benchmarks for accurate performance measurement
{time, warmup, memory_time} =
  if System.get_env("CI") do
    {0.5, 0.1, 0.1}
  else
    {5, 2, 2}
  end

Benchee.run(
  %{
    # Basic operations
    "size()" => fn -> Dictionary.size() end,
    "min_length()" => fn -> Dictionary.min_length() end,
    "max_length()" => fn -> Dictionary.max_length() end,
    "all()" => fn -> Dictionary.all() end,

    # Count operations
    "count_between(4, 8)" => fn -> Dictionary.count_between(4, 8) end,
    "count_between(3, 5)" => fn -> Dictionary.count_between(3, 5) end,
    "count_between(3, 10)" => fn -> Dictionary.count_between(3, 10) end,

    # Common ranges use precomputed tuples; other ranges use a by-length fallback.
    "random_word_between(4, 6)" => fn -> Dictionary.random_word_between(4, 6) end,
    "random_word_between(4, 8)" => fn -> Dictionary.random_word_between(4, 8) end,
    "random_word_between(3, 10)" => fn -> Dictionary.random_word_between(3, 10) end
  },
  time: time,
  memory_time: memory_time,
  warmup: warmup,
  formatters: [
    Benchee.Formatters.Console,
    {Benchee.Formatters.Markdown, file: "bench/output/dictionary.md"}
  ],
  print: [
    benchmarking: true,
    fast_warning: false,
    configuration: true
  ]
)

IO.puts("\n")
IO.puts("=== Dictionary Statistics ===")
IO.puts("Total words: #{Dictionary.size()}")
IO.puts("Min length: #{Dictionary.min_length()}")
IO.puts("Max length: #{Dictionary.max_length()}")
IO.puts("\nWord count by range:")

[{3, 5}, {4, 8}, {6, 10}]
|> Enum.each(fn {min, max} ->
  count = Dictionary.count_between(min, max)
  IO.puts("  Length #{min}-#{max}: #{count} words")
end)

IO.puts("\nThe built-in dictionary uses compile-time indexes.")
IO.puts("Custom dictionaries use :persistent_term and by-length indexes.")
