defmodule ExkPasswd.EntropyTest do
  @moduledoc """
  Tests for ExkPasswd.Entropy calculations.
  """
  use ExUnit.Case, async: true
  doctest ExkPasswd.Entropy

  alias ExkPasswd.{Config, Entropy}

  describe "calculate_blind/1" do
    test "calculates entropy for non-empty password" do
      result = Entropy.calculate_blind("test-password-123")
      assert is_float(result)
      assert result > 0
    end

    test "returns 0 for empty password" do
      result = Entropy.calculate_blind("")
      assert result == 0.0
    end

    test "handles single character password" do
      result = Entropy.calculate_blind("a")
      assert is_float(result)
      assert result > 0
    end
  end

  describe "calculate_seen/1" do
    test "calculates entropy for config" do
      config = Config.new!(num_words: 3)
      result = Entropy.calculate_seen(config)
      assert is_float(result)
      assert result > 0
    end

    test "handles config with no separator" do
      config = Config.new!(num_words: 3, separator: "")
      result = Entropy.calculate_seen(config)
      assert is_float(result)
      assert result > 0
    end

    test "handles config with single char separator" do
      config = Config.new!(num_words: 3, separator: "-")
      result = Entropy.calculate_seen(config)
      assert is_float(result)
      assert result > 0
    end
  end

  describe "calculate_seen_detailed/1" do
    test "returns detailed entropy breakdown" do
      config = Config.new!(num_words: 3, digits: {2, 2})
      result = Entropy.calculate_seen_detailed(config)

      assert is_float(result.word_entropy)
      assert is_float(result.separator_entropy)
      assert is_float(result.digit_entropy)
      assert is_float(result.padding_entropy)
      assert is_float(result.total)
    end

    test "separator entropy is 0 with empty separator" do
      config = Config.new!(num_words: 3, separator: "")
      result = Entropy.calculate_seen_detailed(config)
      assert result.separator_entropy == 0.0
    end

    test "padding entropy is 0 with no padding" do
      config = Config.new!(padding: %{char: "", before: 0, after: 0, to_length: 0})
      result = Entropy.calculate_seen_detailed(config)
      assert result.padding_entropy == 0.0
    end

    test "handles config with padding to_length" do
      config = Config.new!(padding: %{char: "!", before: 0, after: 0, to_length: 50})
      result = Entropy.calculate_seen_detailed(config)
      assert is_float(result.padding_entropy)
    end
  end

  describe "estimate_crack_time/1" do
    test "estimates time for low entropy" do
      result = Entropy.estimate_crack_time(10)
      assert is_binary(result)
      assert result =~ ~r/instant|second|minute|hour/
    end

    test "estimates time for medium entropy" do
      result = Entropy.estimate_crack_time(30)
      assert is_binary(result)
    end

    test "estimates time for high entropy" do
      result = Entropy.estimate_crack_time(60)
      assert is_binary(result)
    end

    test "estimates time for very high entropy" do
      result = Entropy.estimate_crack_time(100)
      assert is_binary(result)
    end

    test "estimates time for extremely high entropy" do
      result = Entropy.estimate_crack_time(200)
      assert is_binary(result)
    end
  end

  describe "determine_status/2" do
    test "returns weak for low entropy" do
      assert Entropy.determine_status(25, 30) == :weak
    end

    test "returns fair for medium-low entropy" do
      assert Entropy.determine_status(40, 45) == :fair
    end

    test "returns good for medium-high entropy" do
      assert Entropy.determine_status(55, 60) == :good
    end

    test "returns excellent for high entropy" do
      assert Entropy.determine_status(80, 85) == :excellent
    end

    test "uses exact threshold values" do
      assert Entropy.determine_status(30, 30) == :weak
      assert Entropy.determine_status(45, 45) == :fair
      assert Entropy.determine_status(60, 60) == :good
      assert Entropy.determine_status(85, 85) == :excellent
    end
  end

  describe "edge cases for entropy calculations" do
    test "handles config with empty padding character" do
      config = Config.new!(padding: %{char: "", before: 5, after: 5, to_length: 0})
      result = Entropy.calculate_seen_detailed(config)
      # Empty padding char means no entropy from padding
      assert result.padding_entropy == 0.0
    end

    test "handles config with padding set but char_count > 1" do
      config = Config.new!(padding: %{char: "!@$", before: 2, after: 2, to_length: 0})
      result = Entropy.calculate_seen_detailed(config)
      # Multi-char padding should have entropy
      assert result.padding_entropy > 0.0
    end

    test "handles config with atom dictionary" do
      ExkPasswd.Dictionary.init()
      # :eff is the default dictionary
      config = Config.new!(num_words: 3, dictionary: :eff)
      result = Entropy.calculate_seen_detailed(config)
      assert result.word_entropy > 0.0
    end

    test "handles config with custom dictionary" do
      ExkPasswd.Dictionary.init()
      ExkPasswd.Dictionary.load_custom(:test_entropy_dict, ["apple", "banana", "cherry", "date"])

      config =
        Config.new!(
          num_words: 3,
          dictionary: :test_entropy_dict,
          word_length: 4..6,
          word_length_bounds: 1..10
        )

      result = Entropy.calculate_seen_detailed(config)
      assert result.word_entropy > 0.0
    end

    test "handles substitution_mode :random" do
      config = Config.new!(num_words: 3) |> Map.put(:substitution_mode, :random)
      result = Entropy.calculate_seen_detailed(config)
      # Random substitution adds 1 bit per word
      assert result.substitution_entropy == 3.0
    end

    test "handles substitution_mode :always" do
      config = Config.new!(num_words: 3) |> Map.put(:substitution_mode, :always)
      result = Entropy.calculate_seen_detailed(config)
      # Always substitution is deterministic, no entropy
      assert result.substitution_entropy == 0.0
    end

    test "handles word_length range with no matching words" do
      # Use extreme word length range that might have no words
      config = Config.new!(num_words: 3, word_length: 10..10)
      result = Entropy.calculate_seen_detailed(config)
      # Should handle gracefully (may be 0 or calculated based on available words)
      assert is_float(result.word_entropy)
    end

    test "handles config with no digits" do
      config = Config.new!(num_words: 3, digits: {0, 0})
      result = Entropy.calculate_seen_detailed(config)
      assert result.digit_entropy == 0.0
    end

    test "handles config with only before digits" do
      config = Config.new!(num_words: 3, digits: {3, 0})
      result = Entropy.calculate_seen_detailed(config)
      # 3 digits = log2(10^3) ≈ 9.97 bits
      assert_in_delta result.digit_entropy, 9.97, 0.1
    end

    test "handles config with only after digits" do
      config = Config.new!(num_words: 3, digits: {0, 2})
      result = Entropy.calculate_seen_detailed(config)
      # 2 digits = log2(10^2) ≈ 6.64 bits
      assert_in_delta result.digit_entropy, 6.64, 0.1
    end

    test "handles case_transform :random entropy" do
      config = Config.new!(num_words: 4, case_transform: :random)
      result = Entropy.calculate_seen_detailed(config)
      # Random case adds 1 bit per word
      assert result.case_entropy == 4.0
    end

    test "handles case_transform deterministic modes" do
      for mode <- [:upper, :lower, :capitalize, :invert, :alternate, :none] do
        config = Config.new!(num_words: 3, case_transform: mode)
        result = Entropy.calculate_seen_detailed(config)
        assert result.case_entropy == 0.0, "Failed for case_transform: #{mode}"
      end
    end
  end

  describe "effective_entropy/2" do
    test "returns minimum of blind and seen" do
      assert Entropy.effective_entropy(80.0, 65.0) == 65.0
      assert Entropy.effective_entropy(50.0, 70.0) == 50.0
      assert Entropy.effective_entropy(60.0, 60.0) == 60.0
    end
  end

  describe "calculate/2" do
    test "returns complete entropy result" do
      config = Config.new!(num_words: 3)
      password = "12-HAPPY-forest-DANCE-56"
      result = Entropy.calculate(password, config)

      assert is_float(result.blind)
      assert is_float(result.seen)
      assert result.status in [:excellent, :good, :fair, :weak]
      assert is_binary(result.blind_crack_time)
      assert is_binary(result.seen_crack_time)
      assert is_map(result.details)
    end
  end

  describe "format_time edge cases" do
    test "formats very small times as instant" do
      result = Entropy.estimate_crack_time(0)
      assert result == "instant"
    end

    test "formats times in seconds range" do
      # Need higher entropy to reach seconds (30 bits => ~500 seconds)
      result = Entropy.estimate_crack_time(32)

      assert String.contains?(result, "second") or String.contains?(result, "minute") or
               String.contains?(result, "hour")
    end

    test "formats times in minutes range" do
      result = Entropy.estimate_crack_time(40)
      assert String.contains?(result, "minute") or String.contains?(result, "hour")
    end

    test "formats times in hours range" do
      result = Entropy.estimate_crack_time(45)
      assert String.contains?(result, "hour") or String.contains?(result, "day")
    end

    test "formats times in days range" do
      result = Entropy.estimate_crack_time(50)
      assert String.contains?(result, "day") or String.contains?(result, "year")
    end

    test "formats times in years range" do
      result = Entropy.estimate_crack_time(58)
      assert String.contains?(result, "year") or String.contains?(result, "centur")
    end

    test "formats times in centuries range" do
      result = Entropy.estimate_crack_time(75)
      assert String.contains?(result, "centur") or String.contains?(result, "millennia")
    end

    test "formats times in millennia range" do
      result = Entropy.estimate_crack_time(85)
      assert String.contains?(result, "millennia") or String.contains?(result, "billion")
    end

    test "formats very large times as billions of years" do
      result = Entropy.estimate_crack_time(150)
      assert result == "billions of years"
    end

    test "formats time exactly at 1 second" do
      # Find entropy that gives exactly ~1 second
      result = Entropy.estimate_crack_time(12)
      assert is_binary(result)
    end

    test "formats time in hours boundary" do
      # ~3600 seconds = 1 hour
      result = Entropy.estimate_crack_time(43)
      assert is_binary(result)
      assert String.contains?(result, "hour") or String.contains?(result, "day")
    end

    test "formats time in days boundary" do
      # ~86400 seconds = 1 day
      result = Entropy.estimate_crack_time(48)
      assert is_binary(result)
    end

    test "formats time in years boundary" do
      # ~31536000 seconds = 1 year
      result = Entropy.estimate_crack_time(56)
      assert is_binary(result)
    end

    test "formats time in centuries boundary" do
      # 100 years
      result = Entropy.estimate_crack_time(63)
      assert is_binary(result)
    end

    test "formats time in millennia boundary" do
      # 1000 years
      result = Entropy.estimate_crack_time(72)
      assert is_binary(result)
    end

    test "formats time beyond millennia" do
      result = Entropy.estimate_crack_time(95)
      assert is_binary(result)
    end
  end

  describe "format_time exact boundaries" do
    test "formats exactly 1 second" do
      # 1 second = 2 * 1e9 guesses, log2(2e9) ≈ 30.93 bits
      result = Entropy.estimate_crack_time(30.93)
      assert String.contains?(result, "second")
    end

    test "formats exactly 60 seconds (boundary to minutes)" do
      # 60 seconds = 120e9 guesses, log2(120e9) ≈ 36.82 bits
      result = Entropy.estimate_crack_time(36.82)
      assert String.contains?(result, "minute") or String.contains?(result, "second")
    end

    test "formats exactly 3600 seconds (boundary to hours)" do
      # 3600 seconds = 7.2e12 guesses, log2(7.2e12) ≈ 42.72 bits
      result = Entropy.estimate_crack_time(42.72)
      assert String.contains?(result, "hour") or String.contains?(result, "minute")
    end

    test "formats exactly 86400 seconds (boundary to days)" do
      # 86400 seconds = 1.728e14 guesses, log2(1.728e14) ≈ 47.29 bits
      result = Entropy.estimate_crack_time(47.29)
      assert String.contains?(result, "day") or String.contains?(result, "hour")
    end

    test "formats exactly 31536000 seconds (boundary to years)" do
      # 31536000 seconds (1 year), log2(6.3072e16) ≈ 55.8 bits
      result = Entropy.estimate_crack_time(55.8)
      assert String.contains?(result, "year") or String.contains?(result, "day")
    end

    test "formats exactly 3153600000 seconds (boundary to centuries)" do
      # 100 years, log2(6.3072e18) ≈ 62.47 bits
      result = Entropy.estimate_crack_time(62.47)
      assert String.contains?(result, "centur") or String.contains?(result, "year")
    end

    test "formats exactly 31536000000 seconds (boundary to millennia)" do
      # 1000 years, log2(6.3072e19) ≈ 65.79 bits
      result = Entropy.estimate_crack_time(65.79)
      assert String.contains?(result, "millennia") or String.contains?(result, "centur")
    end

    test "formats exactly 315360000000000 seconds (boundary to billions of years)" do
      # 10 million years, log2(6.3072e23) ≈ 79.09 bits
      result = Entropy.estimate_crack_time(79.09)
      assert String.contains?(result, "billion") or String.contains?(result, "millennia")
    end

    test "formats less than 1 second as instant" do
      # Very low entropy that results in < 1 second
      result = Entropy.estimate_crack_time(0.5)
      assert result == "instant"
    end

    test "formats 0 entropy as instant" do
      result = Entropy.estimate_crack_time(0)
      assert result == "instant"
    end

    test "formats negative entropy as instant" do
      result = Entropy.estimate_crack_time(-10)
      assert result == "instant"
    end
  end

  describe "edge cases for word entropy calculation" do
    test "handles config with very restrictive word length (few matches)" do
      # Create config with word length that matches very few words
      # Using max allowed (50) which should have very few or no matches
      config =
        Config.new!(
          num_words: 3,
          word_length: 45..50,
          word_length_bounds: 1..50,
          separator: "-"
        )

      result = Entropy.calculate_seen(config)
      # Should handle low/zero word count gracefully
      assert is_float(result)
    end

    test "handles config with custom dictionary atom" do
      # First load a custom dictionary
      words = ["alpha", "bravo", "charlie", "delta", "echo"]
      ExkPasswd.Dictionary.load_custom(:test_entropy_dict, words)

      config =
        Config.new!(
          num_words: 2,
          word_length: 4..7,
          separator: "-",
          dictionary: :test_entropy_dict
        )

      result = Entropy.calculate_seen(config)
      assert is_float(result)
      assert result > 0
    end

    test "handles config with substitution_mode :random" do
      config =
        Config.new!(
          num_words: 3,
          word_length: 4..8,
          separator: "-"
        )
        |> Map.put(:substitution_mode, :random)

      result = Entropy.calculate_seen(config)
      assert is_float(result)
      # Should include entropy from random substitution (1 bit per word)
      assert result > 0
    end

    test "handles config with substitution_mode :always" do
      config =
        Config.new!(
          num_words: 3,
          word_length: 4..8,
          separator: "-"
        )
        |> Map.put(:substitution_mode, :always)

      result = Entropy.calculate_seen(config)
      assert is_float(result)
      assert result > 0
    end

    test "handles empty custom dictionary" do
      # Load an empty dictionary
      ExkPasswd.Dictionary.load_custom(:empty_dict, [])

      config =
        Config.new!(
          num_words: 2,
          word_length: 4..8,
          separator: "-",
          dictionary: :empty_dict
        )

      result = Entropy.calculate_seen(config)
      # Should handle zero word count gracefully (word entropy = 0, but other entropy may exist)
      assert is_float(result)
      # Result includes separator entropy, digit entropy, etc. - just verify it doesn't crash
      assert result >= 0.0
    end
  end
end
