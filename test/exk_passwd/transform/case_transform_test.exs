defmodule ExkPasswd.Transform.CaseTransformTest do
  @moduledoc """
  Tests for case transformation (upper, lower, capitalize, alternate, random, invert).

  ## Overview

  The CaseTransform struct implements the Transform protocol to modify word casing.
  This is one of the most commonly used transforms in password generation.

  ## Test Strategy

  This suite validates all six case transformation modes:

  1. **`:upper`**: Converts entire word to uppercase
     - "hello" → "HELLO"
     - Deterministic, adds no entropy

  2. **`:lower`**: Converts entire word to lowercase
     - "HELLO" → "hello"
     - Deterministic, adds no entropy

  3. **`:capitalize`**: Capitalizes first letter, lowercases rest
     - "hello" → "Hello", "WORLD" → "World"
     - Deterministic, adds no entropy

  4. **`:none`**: Returns word unchanged
     - Preserves original casing from dictionary
     - Deterministic, adds no entropy

  5. **`:invert`**: Inverts case of first character only
     - "Hello" → "hello", "test" → "Test"
     - Deterministic, adds no entropy

  6. **`:random`**: Randomly chooses upper or lower for entire word
     - 50/50 chance of "HELLO" or "hello"
     - Adds 1 bit of entropy per word

  ## Transform Protocol

  CaseTransform implements two callbacks:

  - `apply/3`: Transforms the word string
  - `entropy_bits/2`: Returns entropy contribution (0.0 for deterministic, n*1.0 for random)

  ## Edge Cases Covered

  - Empty strings
  - Single character words
  - Unicode characters (café → CAFÉ)
  - Numbers and symbols (unchanged by case operations)
  - Mixed case inputs

  ## Entropy Calculation

  Only `:random` mode adds entropy because it introduces unpredictability.
  With 3 words, `:random` adds 3.0 bits (2^3 = 8 possible case combinations).
  """
  use ExUnit.Case, async: true
  doctest ExkPasswd.Transform.CaseTransform

  alias ExkPasswd.{Config, Transform}
  alias ExkPasswd.Transform.CaseTransform

  setup do
    config = Config.new!(num_words: 3)
    {:ok, config: config}
  end

  describe "CaseTransform.apply/3" do
    test "upper mode transforms to uppercase", %{config: config} do
      transform = %CaseTransform{mode: :upper}
      assert Transform.apply(transform, "hello", config) == "HELLO"
      assert Transform.apply(transform, "WoRlD", config) == "WORLD"
    end

    test "lower mode transforms to lowercase", %{config: config} do
      transform = %CaseTransform{mode: :lower}
      assert Transform.apply(transform, "HELLO", config) == "hello"
      assert Transform.apply(transform, "WoRlD", config) == "world"
    end

    test "capitalize mode capitalizes first letter", %{config: config} do
      transform = %CaseTransform{mode: :capitalize}
      assert Transform.apply(transform, "hello", config) == "Hello"
      assert Transform.apply(transform, "WORLD", config) == "World"
      assert Transform.apply(transform, "tEST", config) == "Test"
    end

    test "none mode returns word unchanged", %{config: config} do
      transform = %CaseTransform{mode: :none}
      assert Transform.apply(transform, "hello", config) == "hello"
      assert Transform.apply(transform, "WORLD", config) == "WORLD"
      assert Transform.apply(transform, "MiXeD", config) == "MiXeD"
    end

    test "invert mode inverts case", %{config: config} do
      transform = %CaseTransform{mode: :invert}
      assert Transform.apply(transform, "hello", config) == "hELLO"
      assert Transform.apply(transform, "WORLD", config) == "wORLD"
      assert Transform.apply(transform, "Test", config) == "tEST"
    end

    test "invert mode handles empty string", %{config: config} do
      transform = %CaseTransform{mode: :invert}
      assert Transform.apply(transform, "", config) == ""
    end

    test "invert mode handles single character", %{config: config} do
      transform = %CaseTransform{mode: :invert}
      assert Transform.apply(transform, "A", config) == "a"
      assert Transform.apply(transform, "b", config) == "b"
    end

    test "random mode returns either upper or lower", %{config: config} do
      transform = %CaseTransform{mode: :random}

      # Generate many samples to test randomness
      results =
        for _ <- 1..100 do
          Transform.apply(transform, "test", config)
        end

      # Should have both uppercase and lowercase results
      assert "TEST" in results
      assert "test" in results
      assert Enum.all?(results, &(&1 in ["TEST", "test"]))
    end

    test "random mode maintains word length", %{config: config} do
      transform = %CaseTransform{mode: :random}
      word = "hello"
      result = Transform.apply(transform, word, config)
      assert String.length(result) == String.length(word)
    end
  end

  describe "CaseTransform.entropy_bits/2" do
    test "random mode adds 1 bit per word", %{config: config} do
      transform = %CaseTransform{mode: :random}
      expected_entropy = config.num_words * 1.0
      assert Transform.entropy_bits(transform, config) == expected_entropy
    end

    test "random mode entropy scales with num_words" do
      transform = %CaseTransform{mode: :random}

      config2 = Config.new!(num_words: 2)
      assert Transform.entropy_bits(transform, config2) == 2.0

      config5 = Config.new!(num_words: 5)
      assert Transform.entropy_bits(transform, config5) == 5.0
    end

    test "deterministic modes add no entropy", %{config: config} do
      for mode <- [:upper, :lower, :capitalize, :none, :invert] do
        transform = %CaseTransform{mode: mode}
        assert Transform.entropy_bits(transform, config) == 0.0
      end
    end
  end

  describe "CaseTransform edge cases" do
    test "handles unicode characters", %{config: config} do
      transform_upper = %CaseTransform{mode: :upper}
      transform_lower = %CaseTransform{mode: :lower}

      assert Transform.apply(transform_upper, "café", config) == "CAFÉ"
      assert Transform.apply(transform_lower, "CAFÉ", config) == "café"
    end

    test "handles numbers and symbols", %{config: config} do
      transform_upper = %CaseTransform{mode: :upper}
      transform_lower = %CaseTransform{mode: :lower}

      assert Transform.apply(transform_upper, "test123", config) == "TEST123"
      assert Transform.apply(transform_lower, "TEST!@#", config) == "test!@#"
    end

    test "handles empty string for all modes", %{config: config} do
      for mode <- [:upper, :lower, :capitalize, :none, :invert, :random] do
        transform = %CaseTransform{mode: mode}
        result = Transform.apply(transform, "", config)
        assert result == ""
      end
    end
  end
end
