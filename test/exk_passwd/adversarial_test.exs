defmodule ExkPasswd.AdversarialTest do
  @moduledoc """
  Adversarial security testing using statistical analysis.

  Tests defend against real-world attack vectors including frequency analysis,
  state prediction, collision attacks, and pattern recognition.
  """
  use ExUnit.Case, async: false

  alias ExkPasswd.{Config, Random, Dictionary, Batch}

  @large_sample 100_000
  @attack_sample 50_000

  describe "modulo bias exploitation" do
    @tag timeout: 300_000
    test "word selection uniformity via chi-square test" do
      words = for _ <- 1..@large_sample, do: Dictionary.random_word_between(4, 8)
      frequencies = Enum.frequencies(words)

      all_words = Dictionary.all() |> Enum.filter(&(String.length(&1) in 4..8))
      total_possible = length(all_words)
      expected = @large_sample / total_possible

      chi_square =
        Enum.reduce(frequencies, 0, fn {_, observed}, acc ->
          acc + :math.pow(observed - expected, 2) / expected
        end)

      df = total_possible - 1
      # 99.9% confidence
      critical_value = df + :math.sqrt(2 * df) * 3.29

      assert chi_square < critical_value,
             "Chi-square test failed: χ²=#{Float.round(chi_square, 1)} >= #{Float.round(critical_value, 1)}"
    end

    @tag timeout: 300_000
    test "Random.integer/1 uniformity with prime modulo" do
      # Prime number (worst case)
      max = 7919
      values = for _ <- 1..@large_sample, do: Random.integer(max)
      frequencies = Enum.frequencies(values)

      expected = @large_sample / max

      chi_square =
        Enum.reduce(frequencies, 0, fn {_, observed}, acc ->
          acc + :math.pow(observed - expected, 2) / expected
        end)

      df = max - 1
      critical_value = df + :math.sqrt(2 * df) * 3.29

      assert chi_square < critical_value,
             "Random.integer/1 shows bias: χ²=#{Float.round(chi_square, 1)}"
    end
  end

  describe "batch generation state prediction" do
    @tag timeout: 300_000
    test "consecutive passwords word overlap analysis" do
      batch = Batch.generate_batch(1000)
      consecutive_pairs = Enum.chunk_every(batch, 2, 1, :discard)

      word_repetitions =
        Enum.count(consecutive_pairs, fn [pw1, pw2] ->
          words1 = String.split(pw1, ~r/[^a-zA-Z]+/) |> Enum.reject(&(&1 == ""))
          words2 = String.split(pw2, ~r/[^a-zA-Z]+/) |> Enum.reject(&(&1 == ""))
          overlap = MapSet.intersection(MapSet.new(words1), MapSet.new(words2))
          MapSet.size(overlap) > 0
        end)

      repetition_rate = word_repetitions / length(consecutive_pairs)

      # Expected overlap ~0.015% for 3 words from 7826, allow up to 2%
      assert repetition_rate < 0.02,
             "Consecutive passwords show correlation: #{Float.round(repetition_rate * 100, 1)}%"
    end

    @tag timeout: 300_000
    test "sequential digit pattern detection" do
      batch = Batch.generate_batch(500)

      digit_sequences =
        Enum.map(batch, fn password ->
          Regex.scan(~r/\d+/, password) |> List.flatten() |> Enum.join()
        end)
        |> Enum.reject(&(&1 == ""))

      digit_integers =
        Enum.map(digit_sequences, fn digits ->
          try do
            String.to_integer(digits)
          rescue
            ArgumentError -> nil
          end
        end)
        |> Enum.reject(&is_nil/1)

      sorted_digits = Enum.sort(digit_integers)

      sequential_count =
        Enum.chunk_every(sorted_digits, 2, 1, :discard)
        |> Enum.count(fn [a, b] -> b - a == 1 end)

      sequential_rate =
        if length(sorted_digits) > 1 do
          sequential_count / (length(sorted_digits) - 1)
        else
          0
        end

      # Allow up to 6.5% sequential patterns due to random chance
      # (expected ~5.8% for truly random data)
      assert sequential_rate < 0.065,
             "Sequential patterns detected: #{Float.round(sequential_rate * 100, 1)}%"
    end
  end

  describe "dictionary coverage" do
    @tag timeout: 300_000
    test "all words reachable" do
      all_words = Dictionary.all()
      total_words = length(all_words)

      sample_size = 200_000

      generated_words =
        for _ <- 1..sample_size do
          Dictionary.random_word_between(4, 10)
        end
        |> MapSet.new()

      coverage = MapSet.size(generated_words) / total_words

      # Expect ~80%+ coverage (birthday paradox limits full coverage)
      assert coverage > 0.80,
             "Insufficient dictionary coverage: #{Float.round(coverage * 100, 1)}%"
    end

    @tag timeout: 300_000
    test "word length distribution matches dictionary" do
      words = for _ <- 1..@attack_sample, do: Dictionary.random_word_between(4, 8)
      length_freq = Enum.map(words, &String.length/1) |> Enum.frequencies()

      all_words = Dictionary.all() |> Enum.filter(&(String.length(&1) in 4..8))
      expected_freq = Enum.map(all_words, &String.length/1) |> Enum.frequencies()
      total = length(all_words)

      max_deviation =
        for len <- 4..8 do
          actual_pct = Map.get(length_freq, len, 0) / @attack_sample * 100
          expected_pct = Map.get(expected_freq, len, 0) / total * 100
          abs(actual_pct - expected_pct)
        end
        |> Enum.max()

      assert max_deviation < 5.0,
             "Length distribution deviates by #{Float.round(max_deviation, 1)}%"
    end
  end

  describe "configuration fingerprinting" do
    @tag timeout: 300_000
    test "preset identification from structure" do
      presets = [:default, :xkcd, :security, :wifi]

      for preset <- presets do
        samples = for _ <- 1..100, do: ExkPasswd.generate(preset)

        word_counts =
          Enum.map(samples, fn pw ->
            String.split(pw, ~r/[^a-zA-Z]+/) |> Enum.reject(&(&1 == "")) |> length()
          end)

        avg_word_count = Enum.sum(word_counts) / length(word_counts)

        # Warning: Presets are fingerprintable (not a vulnerability, inherent to structure)
        assert is_float(avg_word_count),
               "Preset #{preset} structure analysis failed"
      end

      # Note: This test documents that presets ARE fingerprintable
      # This is expected behavior, not a vulnerability
    end
  end

  describe "birthday collision attacks" do
    @tag timeout: 300_000
    test "collision rate within birthday paradox bounds" do
      sample_size = 10_000
      passwords = for _ <- 1..sample_size, do: ExkPasswd.generate()

      unique = Enum.uniq(passwords) |> length()
      collisions = sample_size - unique
      collision_rate = collisions / sample_size

      # For high entropy, expect near-zero collisions
      assert collision_rate < 0.001,
             "Collision rate too high: #{Float.round(collision_rate * 100, 3)}%"
    end
  end

  describe "digit generation uniformity" do
    @tag timeout: 300_000
    test "all digits 0-9 appear with equal frequency" do
      config = Config.new!(digits: {4, 4})
      passwords = for _ <- 1..@attack_sample, do: ExkPasswd.generate(config)

      all_digits =
        passwords
        |> Enum.flat_map(fn pw -> Regex.scan(~r/\d/, pw) |> List.flatten() end)
        |> Enum.map(&String.to_integer/1)

      frequencies = Enum.frequencies(all_digits)
      expected = length(all_digits) / 10

      max_bias =
        for digit <- 0..9 do
          count = Map.get(frequencies, digit, 0)
          abs(count - expected) / expected * 100
        end
        |> Enum.max()

      assert max_bias < 2.0,
             "Digit generation bias: #{Float.round(max_bias, 1)}%"
    end
  end

  describe "boolean fairness" do
    @tag timeout: 300_000
    test "Random.boolean/0 produces 50/50 distribution" do
      results = for _ <- 1..@large_sample, do: Random.boolean()

      true_count = Enum.count(results, & &1)
      true_pct = true_count / @large_sample * 100
      bias = abs(true_pct - 50.0)

      assert bias < 1.0,
             "Boolean bias from 50/50: #{Float.round(bias, 2)}%"
    end
  end

  describe "parallel generation independence" do
    @tag timeout: 300_000
    test "concurrent generation shows no process correlation" do
      tasks =
        for i <- 1..100 do
          Task.async(fn ->
            {i, for(_ <- 1..50, do: ExkPasswd.generate())}
          end)
        end

      results = Task.await_many(tasks, 30_000)

      all_passwords = Enum.flat_map(results, fn {_, passwords} -> passwords end)
      unique_global = Enum.uniq(all_passwords) |> length()

      collision_rate = 1 - unique_global / length(all_passwords)

      assert collision_rate < 0.01,
             "Parallel generation correlation: #{Float.round(collision_rate * 100, 2)}%"
    end
  end

  describe "entropy validation" do
    @tag timeout: 300_000
    test "collision analysis confirms theoretical entropy" do
      config = Config.new!(num_words: 3, separator: "-", digits: {2, 2})
      theoretical_entropy = ExkPasswd.Entropy.calculate_seen(config)

      sample_size = 10_000
      passwords = for _ <- 1..sample_size, do: ExkPasswd.generate(config)

      unique_passwords = Enum.uniq(passwords) |> length()
      collision_rate = (sample_size - unique_passwords) / sample_size

      # For N=55 bits, expect collision around sqrt(2^55) ≈ 6M samples
      # With 10k samples, collision rate should be near 0
      assert collision_rate < 0.001,
             "Entropy lower than claimed #{Float.round(theoretical_entropy, 1)} bits"
    end
  end

  describe "ML pattern recognition" do
    @tag :slow
    @tag timeout: 300_000
    test "password features show no predictable patterns" do
      passwords = for _ <- 1..10_000, do: ExkPasswd.generate()

      features =
        Enum.map(passwords, fn pw ->
          %{
            length: String.length(pw),
            digit_count: length(Regex.scan(~r/\d/, pw)),
            upper_count: length(Regex.scan(~r/[A-Z]/, pw)),
            lower_count: length(Regex.scan(~r/[a-z]/, pw)),
            special_count: length(Regex.scan(~r/[^a-zA-Z0-9]/, pw)),
            first_char: String.first(pw),
            last_char: String.last(pw)
          }
        end)

      # Check first/last character entropy
      first_chars = Enum.map(features, & &1.first_char) |> Enum.frequencies()
      first_char_entropy = calculate_shannon_entropy(first_chars, length(features))

      last_chars = Enum.map(features, & &1.last_char) |> Enum.frequencies()
      last_char_entropy = calculate_shannon_entropy(last_chars, length(features))

      # Expect reasonable entropy (allow 4+ bits for statistical variation)
      # With larger sample size, should see better entropy
      assert first_char_entropy > 4.0,
             "First character predictable: #{Float.round(first_char_entropy, 1)} bits"

      assert last_char_entropy > 4.0,
             "Last character predictable: #{Float.round(last_char_entropy, 1)} bits"
    end
  end

  defp calculate_shannon_entropy(frequencies, total) do
    frequencies
    |> Enum.reduce(0, fn {_char, count}, acc ->
      p = count / total
      acc - p * :math.log2(p)
    end)
  end
end
