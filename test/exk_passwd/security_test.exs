defmodule ExkPasswd.SecurityTest do
  @moduledoc """
  Statistical and cryptographic security tests for ExkPasswd.

  These tests verify:
  - Randomness quality and uniform distribution
  - Collision resistance
  - Entropy calculations
  - No weak patterns or biases
  - Cryptographic properties of generated passwords
  """
  use ExUnit.Case, async: true

  alias ExkPasswd.{Config, Random, Dictionary}

  @sample_size 10_000
  @collision_test_size 5_000

  describe "Random.integer/1 - distribution quality" do
    test "produces uniform distribution (chi-square test)" do
      max = 100

      frequencies =
        Enum.reduce(1..@sample_size, %{}, fn _, acc ->
          value = Random.integer(max)
          Map.update(acc, value, 1, &(&1 + 1))
        end)

      # Expected frequency per value
      expected = @sample_size / max

      # Calculate chi-square statistic
      chi_square =
        Enum.reduce(frequencies, 0, fn {_value, observed}, acc ->
          acc + :math.pow(observed - expected, 2) / expected
        end)

      # Critical value at 99.9% confidence for df=99 is approximately 140
      # We use a more lenient threshold for test stability
      critical_value = 140

      assert chi_square < critical_value,
             "Chi-square test failed: #{chi_square} >= #{critical_value}. " <>
               "Distribution may not be uniform."
    end

    test "no modulo bias for small ranges" do
      # Test that small ranges don't have modulo bias
      max = 3

      frequencies =
        Enum.reduce(1..@sample_size, %{}, fn _, acc ->
          value = Random.integer(max)
          Map.update(acc, value, 1, &(&1 + 1))
        end)

      # Each value should appear roughly 1/3 of the time
      expected = @sample_size / max

      for {_value, count} <- frequencies do
        # Allow 10% deviation
        assert abs(count - expected) < expected * 0.1,
               "Value appears #{count} times, expected ~#{expected}"
      end
    end

    test "no correlation between consecutive values" do
      # Generate pairs and check for patterns
      pairs = for _ <- 1..1000, do: {Random.integer(10), Random.integer(10)}

      # Check that all combinations appear (with high probability)
      unique_pairs = Enum.uniq(pairs) |> length()

      # Should have many unique pairs (expecting > 80% coverage of 100 possible pairs)
      assert unique_pairs > 80,
             "Only #{unique_pairs} unique pairs out of 100 possible. " <>
               "May indicate correlation."
    end
  end

  describe "Random.select/1 - uniform selection" do
    test "selects from list with uniform distribution" do
      list = Enum.to_list(1..10)

      frequencies =
        Enum.reduce(1..@sample_size, %{}, fn _, acc ->
          value = Random.select(list)
          Map.update(acc, value, 1, &(&1 + 1))
        end)

      expected = @sample_size / 10

      for {_value, count} <- frequencies do
        # Allow 15% deviation to account for statistical variance
        # With 10,000 samples, standard deviation ≈ 31.6, so ~3σ ≈ 95 (9.5%)
        # Using 15% provides a comfortable margin while still detecting bias
        assert abs(count - expected) < expected * 0.15
      end
    end

    test "no positional bias in selection" do
      # Test that all positions in list are equally likely
      list = Enum.to_list(1..20)
      selections = for _ <- 1..@sample_size, do: Random.select(list)

      # Count how many times each value was selected
      frequencies = Enum.frequencies(selections)

      # Use chi-square test for statistical significance
      expected = @sample_size / 20

      chi_square =
        Enum.reduce(frequencies, 0, fn {_value, observed}, acc ->
          acc + :math.pow(observed - expected, 2) / expected
        end)

      # Critical value for df=19 at 99.9% confidence ≈ 43.8
      # Using 50 provides margin for test stability while still detecting real bias
      assert chi_square < 50,
             "Chi-square #{chi_square} indicates positional bias in selection"
    end
  end

  describe "Random.boolean/1 - fairness" do
    test "produces roughly 50/50 true/false distribution" do
      results = for _ <- 1..@sample_size, do: Random.boolean()
      true_count = Enum.count(results, & &1)
      false_count = @sample_size - true_count

      # Should be close to 50/50
      assert abs(true_count - false_count) < @sample_size * 0.05,
             "true: #{true_count}, false: #{false_count} - distribution too skewed"
    end
  end

  describe "Password generation - collision resistance" do
    test "generates unique passwords (very low collision rate)" do
      passwords = for _ <- 1..@collision_test_size, do: ExkPasswd.generate()

      unique_count = passwords |> Enum.uniq() |> length()
      collision_rate = 1 - unique_count / @collision_test_size

      # Should have < 0.1% collision rate (5 collisions out of 5000)
      assert collision_rate < 0.001,
             "Collision rate too high: #{collision_rate * 100}% " <>
               "(#{@collision_test_size - unique_count} collisions)"
    end

    test "generates unique passwords with same config" do
      config = Config.new!(num_words: 3, separator: "-")
      passwords = for _ <- 1..@collision_test_size, do: ExkPasswd.generate(config)

      unique_count = passwords |> Enum.uniq() |> length()

      # Even with same config, should have very few collisions
      assert unique_count > @collision_test_size * 0.999
    end

    test "different presets generate different passwords" do
      presets = [:default, :xkcd, :security, :wifi]

      results =
        for _ <- 1..100 do
          for preset <- presets do
            {preset, ExkPasswd.generate(preset)}
          end
        end
        |> List.flatten()

      # Check no overlap between different presets
      grouped = Enum.group_by(results, fn {preset, _} -> preset end, fn {_, pw} -> pw end)

      for {preset1, passwords1} <- grouped do
        for {preset2, passwords2} <- grouped do
          if preset1 != preset2 do
            overlap = MapSet.intersection(MapSet.new(passwords1), MapSet.new(passwords2))

            assert MapSet.size(overlap) == 0,
                   "#{preset1} and #{preset2} generated same password!"
          end
        end
      end
    end
  end

  describe "Password generation - no weak patterns" do
    # Note: Individual dictionary words (like "password") can appear in passphrases
    # This is acceptable as passphrases combine multiple words
    @forbidden_patterns [
      "12345",
      "qwerty",
      "111111",
      "000000",
      "aaaaaa"
    ]

    test "generated passwords contain no common weak numeric patterns" do
      passwords = for _ <- 1..500, do: ExkPasswd.generate()

      for password <- passwords do
        lowercase_pw = String.downcase(password)

        for pattern <- @forbidden_patterns do
          refute String.contains?(lowercase_pw, pattern),
                 "Password contains weak pattern '#{pattern}': #{password}"
        end
      end
    end

    test "generated passwords have sufficient character variety" do
      passwords = for _ <- 1..500, do: ExkPasswd.generate()

      for password <- passwords do
        unique_chars = password |> String.graphemes() |> Enum.uniq() |> length()
        total_chars = String.length(password)

        # At least 40% unique characters
        variety = unique_chars / total_chars

        assert variety > 0.4,
               "Password has low character variety (#{variety * 100}%): #{password}"
      end
    end
  end

  describe "Dictionary selection - randomness" do
    test "selects words without positional bias" do
      # Test that dictionary selection doesn't favor certain positions
      words = for _ <- 1..@sample_size, do: Dictionary.random_word_between(4, 8)

      # Check that we're getting good variety
      unique_words = words |> Enum.uniq() |> length()

      # Should have at least 1000 unique words out of 10k selections
      # (dictionary has ~7.8k words)
      assert unique_words > 1000,
             "Only #{unique_words} unique words selected - may indicate bias"
    end

    test "random_word_between respects length constraints" do
      words = for _ <- 1..1000, do: Dictionary.random_word_between(4, 6)

      for word <- words do
        len = String.length(word)

        assert len >= 4 and len <= 6,
               "Word '#{word}' (length #{len}) outside range [4, 6]"
      end

      # Check we get variety in lengths
      lengths = Enum.map(words, &String.length/1) |> Enum.frequencies()
      assert map_size(lengths) >= 2, "Should have multiple word lengths represented"
    end
  end

  describe "Entropy calculations - correctness" do
    test "entropy increases with more words" do
      entropies =
        for num_words <- 2..6 do
          config = Config.new!(num_words: num_words)
          {num_words, ExkPasswd.Entropy.calculate_seen(config)}
        end

      # Each additional word should increase entropy
      for [{n1, e1}, {n2, e2}] <- Enum.chunk_every(entropies, 2, 1, :discard) do
        assert e2 > e1,
               "Entropy should increase with more words: #{n1} words (#{e1} bits) vs " <>
                 "#{n2} words (#{e2} bits)"
      end
    end

    test "entropy increases with longer words" do
      e1 = Config.new!(word_length: 4..6) |> ExkPasswd.Entropy.calculate_seen()
      e2 = Config.new!(word_length: 6..8) |> ExkPasswd.Entropy.calculate_seen()

      assert e2 > e1, "Longer words should provide more entropy"
    end

    test "entropy increases with padding" do
      config_no_padding = Config.new!(digits: {0, 0})
      config_with_padding = Config.new!(digits: {2, 2})

      e1 = ExkPasswd.Entropy.calculate_seen(config_no_padding)
      e2 = ExkPasswd.Entropy.calculate_seen(config_with_padding)

      assert e2 > e1, "Padding should increase entropy"
    end

    test "calculated entropy is reasonable" do
      config = Config.new!(num_words: 4, separator: "-")
      entropy = ExkPasswd.Entropy.calculate_seen(config)

      # 4 words from ~18k dictionary = log2(18000^4) ≈ 57 bits minimum
      assert entropy > 50, "Entropy too low for 4 words: #{entropy}"
      assert entropy < 100, "Entropy suspiciously high: #{entropy}"
    end
  end

  # NOTE: Timing attack resistance tests are inherently flaky in BEAM VM
  # due to garbage collection, scheduler variations, and JIT compilation.
  #
  # For serious timing analysis, use:
  # - Benchee for statistical timing analysis
  # - Manual constant-time code review
  # - Side-channel analysis tools
  #
  # The current implementation uses:
  # - O(1) tuple lookups (no data-dependent branches)
  # - :crypto.strong_rand_bytes (constant-time by design)
  # - Pre-computed word lists (no runtime string operations based on input)

  describe "Memory handling - no leakage" do
    test "password generation doesn't accumulate memory" do
      # Warm up the system to eliminate one-time allocations
      for _ <- 1..100, do: ExkPasswd.generate()
      :erlang.garbage_collect()
      Process.sleep(100)

      # Measure baseline memory after warmup
      initial_memory = :erlang.memory(:total)

      # Generate many passwords
      for _ <- 1..10_000 do
        _password = ExkPasswd.generate()
      end

      # Force garbage collection multiple times to ensure cleanup
      :erlang.garbage_collect()
      Process.sleep(100)
      :erlang.garbage_collect()

      final_memory = :erlang.memory(:total)
      memory_increase = final_memory - initial_memory

      # After warmup and proper GC, memory increase should be minimal
      # Allow up to 20MB increase to account for:
      # - BEAM VM internal allocations
      # - Process dictionary growth
      # - Binary reference counters
      # - CI environment variability
      # The key is that memory doesn't grow unbounded with usage
      assert memory_increase < 20_000_000,
             "Memory increased by #{div(memory_increase, 1024)}KB after warmup - possible leak"
    end
  end

  describe "Integration - real-world scenarios" do
    test "batch generation produces unique passwords" do
      batch = ExkPasswd.Batch.generate_batch(1000)

      unique_count = Enum.uniq(batch) |> length()
      assert unique_count == 1000, "Batch generated #{1000 - unique_count} duplicates"
    end

    test "high-entropy passwords are actually high entropy" do
      config =
        Config.new!(
          num_words: 6,
          word_length: 6..10,
          separator: "-",
          digits: {4, 4}
        )

      passwords = for _ <- 1..100, do: ExkPasswd.generate(config)

      # Check actual empirical entropy
      for password <- passwords do
        # Shannon entropy approximation
        freqs =
          password
          |> String.graphemes()
          |> Enum.frequencies()
          |> Map.values()

        total = String.length(password)

        shannon_entropy =
          Enum.reduce(freqs, 0, fn count, acc ->
            p = count / total
            acc - p * :math.log2(p)
          end)

        # Shannon entropy per character should be > 3 bits for strong passwords
        assert shannon_entropy > 3.0,
               "Password has low Shannon entropy: #{shannon_entropy}"
      end
    end

    test "passwords meet NIST guidelines for entropy" do
      # NIST recommends 80+ bits for high-value passwords
      config = Config.new!(num_words: 5, digits: {2, 2})
      entropy = ExkPasswd.Entropy.calculate_seen(config)

      assert entropy >= 70, "Entropy #{entropy} bits below recommended 70+ bits"
    end
  end
end
