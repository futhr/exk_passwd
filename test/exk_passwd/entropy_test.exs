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
  end
end
