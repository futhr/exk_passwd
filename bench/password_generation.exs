# Benchmark password generation performance
#
# Run with: mix run bench/password_generation.exs
#
# This benchmarks the core password generation functions to ensure
# performance remains acceptable as the library evolves.

alias ExkPasswd.{Dictionary, Password, Config, Token}

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

word_count_configs = Map.new(3..6, &{&1, Config.new!(num_words: &1)})

case_configs =
  Map.new([:lower, :upper, :capitalize, :alternate, :random], fn mode ->
    {mode, Config.new!(case_transform: mode)}
  end)

Benchee.run(
  %{
    # Core generation functions
    "generate() default" => fn -> ExkPasswd.generate() end,
    "generate(:xkcd)" => fn -> ExkPasswd.generate(:xkcd) end,
    "generate(:web32)" => fn -> ExkPasswd.generate(:web32) end,
    "generate(:wifi)" => fn -> ExkPasswd.generate(:wifi) end,
    "generate(:security)" => fn -> ExkPasswd.generate(:security) end,

    # Dictionary operations
    "Dictionary.all()" => fn -> Dictionary.all() end,
    "Dictionary.size()" => fn -> Dictionary.size() end,
    "Dictionary.random_word_between(4, 8)" => fn -> Dictionary.random_word_between(4, 8) end,
    "Dictionary.count_between(4, 8)" => fn -> Dictionary.count_between(4, 8) end,

    # Password creation with different word counts
    "create() 3 words" => fn ->
      Password.create(word_count_configs[3])
    end,
    "create() 4 words" => fn ->
      Password.create(word_count_configs[4])
    end,
    "create() 5 words" => fn ->
      Password.create(word_count_configs[5])
    end,
    "create() 6 words" => fn ->
      Password.create(word_count_configs[6])
    end,

    # Token generation
    "Token.get_number(2)" => fn -> Token.get_number(2) end,
    "Token.get_number(4)" => fn -> Token.get_number(4) end,

    # Case transformations
    "transform :lower" => fn ->
      Password.create(case_configs.lower)
    end,
    "transform :upper" => fn ->
      Password.create(case_configs.upper)
    end,
    "transform :capitalize" => fn ->
      Password.create(case_configs.capitalize)
    end,
    "transform :alternate" => fn ->
      Password.create(case_configs.alternate)
    end,
    "transform :random" => fn ->
      Password.create(case_configs.random)
    end
  },
  time: time,
  memory_time: memory_time,
  warmup: warmup,
  formatters: [
    Benchee.Formatters.Console,
    {Benchee.Formatters.Markdown, file: "bench/output/password_generation.md"}
  ],
  print: [
    benchmarking: true,
    fast_warning: false,
    configuration: true
  ]
)
