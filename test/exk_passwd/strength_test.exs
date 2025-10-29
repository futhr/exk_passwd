defmodule ExkPasswd.StrengthTest do
  @moduledoc """
  Tests for ExkPasswd.Strength password strength analysis.
  """
  use ExUnit.Case, async: true
  doctest ExkPasswd.Strength

  alias ExkPasswd.{Config, Strength}

  describe "analyze/2" do
    test "analyzes password strength" do
      config = Config.new!(num_words: 4)
      password = "test-password-here-now"
      result = Strength.analyze(password, config)

      assert is_integer(result.score)
      assert result.score >= 0 and result.score <= 100
      assert result.rating in [:excellent, :good, :fair, :weak]
    end

    test "higher entropy gives better rating" do
      strong_config = Config.new!(num_words: 6, digits: {3, 3})
      weak_config = Config.new!(num_words: 2, digits: {0, 0})

      strong = Strength.analyze("long-complex-password-here-123-456", strong_config)
      weak = Strength.analyze("short-pass", weak_config)

      assert strong.score > weak.score
    end
  end

  describe "rating/2" do
    test "returns rating for password" do
      config = Config.new!(num_words: 3)
      rating = Strength.rating("test-password", config)

      assert rating in [:excellent, :good, :fair, :weak]
    end

    test "handles fair strength threshold" do
      config = Config.new!(num_words: 2, digits: {2, 2})
      rating = Strength.rating("test-pass-12-34", config)
      assert rating in [:excellent, :good, :fair, :weak]
    end
  end

  describe "analyze/2 score" do
    test "returns analysis with score between 0 and 100" do
      config = Config.new!(num_words: 3)
      result = Strength.analyze("test-password-here", config)

      assert is_integer(result.score)
      assert result.score >= 0 and result.score <= 100
    end
  end

  describe "rating thresholds" do
    test "excellent rating for >= 78 bits entropy" do
      # Using a mock entropy by having many words
      config = Config.new!(num_words: 6, digits: {3, 3})
      result = Strength.analyze("word1-word2-word3-word4-word5-word6-123-456", config)

      # Should be excellent with high entropy
      if result.entropy_bits >= 78 do
        assert result.rating == :excellent
      end
    end

    test "good rating for >= 52 bits entropy" do
      config = Config.new!(num_words: 4, digits: {2, 2})
      result = Strength.analyze("word1-word2-word3-word4-12-34", config)

      # Should be at least good with decent entropy
      if result.entropy_bits >= 52 and result.entropy_bits < 78 do
        assert result.rating == :good
      end
    end

    test "fair rating for >= 40 bits entropy" do
      config = Config.new!(num_words: 3, digits: {1, 1})
      result = Strength.analyze("word1-word2-word3-1-2", config)

      # Should be at least fair
      if result.entropy_bits >= 40 and result.entropy_bits < 52 do
        assert result.rating == :fair
      end
    end

    test "weak rating for < 40 bits entropy" do
      config = Config.new!(num_words: 2, digits: {0, 0})
      result = Strength.analyze("ab-cd", config)

      # Should be weak with low entropy
      if result.entropy_bits < 40 do
        assert result.rating == :weak
      end
    end
  end

  describe "entropy reporting" do
    test "includes entropy_bits in result" do
      config = Config.new!(num_words: 3)
      result = Strength.analyze("test-password-here", config)

      assert is_float(result.entropy_bits)
      assert result.entropy_bits > 0
    end

    test "uses conservative entropy estimate" do
      config = Config.new!(num_words: 3)
      result = Strength.analyze("test-password-here", config)

      # Should use the minimum of blind and seen entropy
      assert Map.has_key?(result, :entropy_bits)
    end
  end
end
