defmodule ExkPasswd.TransformTest do
  @moduledoc """
  Tests for the ExkPasswd.Transform protocol.

  This module tests the Transform protocol definition and verifies that
  built-in implementations correctly implement the protocol contract.

  ## Test Strategy

  - **Protocol compliance**: Verify `apply/3` and `entropy_bits/2` work correctly
  - **Built-in transforms**: Test CaseTransform, Substitution, Pinyin, Romaji
  - **Transform chaining**: Multiple transforms applied in sequence via config meta
  - **Entropy contribution**: Correct entropy calculation from various transforms
  - **Edge cases**: Empty strings, unicode, special characters

  ## Protocol Design

  The Transform protocol defines two callbacks:

  1. `apply/3` - Transforms a word/component string
  2. `entropy_bits/2` - Returns entropy contribution in bits

  Implementations must be defined at compile time (protocol consolidation).
  Custom transforms should be defined in the application, not in tests.

  ## Coverage Focus

  These tests ensure the protocol works correctly with all built-in
  implementations and that transforms integrate properly with the
  password generation pipeline via the Config meta field.
  """
  use ExUnit.Case, async: true

  alias ExkPasswd.{Config, Transform}
  alias ExkPasswd.Transform.{CaseTransform, Pinyin, Romaji, Substitution}

  describe "Transform.apply/3 with CaseTransform" do
    setup do
      {:ok, config: Config.new!(num_words: 3)}
    end

    test "upper mode converts to uppercase", %{config: config} do
      transform = %CaseTransform{mode: :upper}
      assert Transform.apply(transform, "hello", config) == "HELLO"
      assert Transform.apply(transform, "World", config) == "WORLD"
    end

    test "lower mode converts to lowercase", %{config: config} do
      transform = %CaseTransform{mode: :lower}
      assert Transform.apply(transform, "HELLO", config) == "hello"
      assert Transform.apply(transform, "World", config) == "world"
    end

    test "capitalize mode capitalizes first letter", %{config: config} do
      transform = %CaseTransform{mode: :capitalize}
      assert Transform.apply(transform, "hello", config) == "Hello"
      assert Transform.apply(transform, "WORLD", config) == "World"
    end

    test "invert mode inverts case pattern", %{config: config} do
      transform = %CaseTransform{mode: :invert}
      assert Transform.apply(transform, "Hello", config) == "hELLO"
      assert Transform.apply(transform, "world", config) == "wORLD"
    end

    test "none mode preserves original", %{config: config} do
      transform = %CaseTransform{mode: :none}
      assert Transform.apply(transform, "HeLLo", config) == "HeLLo"
    end

    test "random mode returns upper or lower", %{config: config} do
      transform = %CaseTransform{mode: :random}

      results =
        for _ <- 1..100 do
          Transform.apply(transform, "hello", config)
        end

      assert "HELLO" in results
      assert "hello" in results
      assert Enum.all?(results, &(&1 in ["hello", "HELLO"]))
    end
  end

  describe "Transform.apply/3 with Substitution" do
    setup do
      {:ok, config: Config.new!(num_words: 3)}
    end

    test "always mode applies all substitutions", %{config: config} do
      transform = %Substitution{map: %{"e" => "3", "o" => "0"}, mode: :always}
      assert Transform.apply(transform, "hello", config) == "h3ll0"
    end

    test "none mode returns unchanged", %{config: config} do
      transform = %Substitution{map: %{"e" => "3"}, mode: :none}
      assert Transform.apply(transform, "hello", config) == "hello"
    end

    test "random mode randomly applies substitutions", %{config: config} do
      transform = %Substitution{map: %{"e" => "3", "o" => "0"}, mode: :random}

      results =
        for _ <- 1..100 do
          Transform.apply(transform, "hello", config)
        end

      assert "h3ll0" in results
      assert "hello" in results
    end

    test "handles empty substitution map", %{config: config} do
      transform = %Substitution{map: %{}, mode: :always}
      assert Transform.apply(transform, "hello", config) == "hello"
    end
  end

  describe "Transform.entropy_bits/2" do
    setup do
      {:ok, config: Config.new!(num_words: 4)}
    end

    test "deterministic CaseTransform modes add no entropy", %{config: config} do
      for mode <- [:upper, :lower, :capitalize, :invert, :none] do
        transform = %CaseTransform{mode: mode}

        assert Transform.entropy_bits(transform, config) == 0.0,
               "Expected 0.0 entropy for mode #{mode}"
      end
    end

    test "random CaseTransform adds 1 bit per word", %{config: config} do
      transform = %CaseTransform{mode: :random}
      # 4 words * 1 bit each = 4.0 bits
      assert Transform.entropy_bits(transform, config) == 4.0
    end

    test "deterministic Substitution modes add no entropy", %{config: config} do
      for mode <- [:none, :always] do
        transform = %Substitution{map: %{"e" => "3"}, mode: mode}

        assert Transform.entropy_bits(transform, config) == 0.0,
               "Expected 0.0 entropy for mode #{mode}"
      end
    end

    test "random Substitution adds 1 bit per word", %{config: config} do
      transform = %Substitution{map: %{"e" => "3"}, mode: :random}
      # 4 words * 1 bit each = 4.0 bits
      assert Transform.entropy_bits(transform, config) == 4.0
    end

    test "entropy scales with num_words" do
      transform = %CaseTransform{mode: :random}

      config2 = Config.new!(num_words: 2)
      assert Transform.entropy_bits(transform, config2) == 2.0

      config6 = Config.new!(num_words: 6)
      assert Transform.entropy_bits(transform, config6) == 6.0
    end

    test "Pinyin transform adds no entropy" do
      config = Config.new!(num_words: 3)
      transform = %Pinyin{}
      assert Transform.entropy_bits(transform, config) == 0.0
    end

    test "Romaji transform adds no entropy" do
      config = Config.new!(num_words: 3)
      transform = %Romaji{}
      assert Transform.entropy_bits(transform, config) == 0.0
    end
  end

  describe "transform chaining via config meta" do
    test "multiple transforms are applied in sequence" do
      config =
        Config.new!(
          num_words: 2,
          separator: "-",
          digits: {0, 0},
          padding: %{char: "", before: 0, after: 0, to_length: 0},
          case_transform: :lower,
          meta: %{
            transforms: [
              %CaseTransform{mode: :upper},
              %Substitution{map: %{"E" => "3", "A" => "@"}, mode: :always}
            ]
          }
        )

      password = ExkPasswd.generate(config)
      assert is_binary(password)

      # Words should be uppercase with substitutions applied
      parts = String.split(password, "-")
      assert length(parts) == 2

      for part <- parts do
        # Should not contain lowercase letters (all uppercase or substituted)
        refute String.match?(part, ~r/[a-z]/),
               "Expected no lowercase in #{part}"
      end
    end

    test "empty transforms list doesn't affect password" do
      config =
        Config.new!(
          num_words: 2,
          separator: "-",
          meta: %{transforms: []}
        )

      password = ExkPasswd.generate(config)
      assert is_binary(password)
      assert password =~ "-"
    end

    test "nil transforms key doesn't affect password" do
      config =
        Config.new!(
          num_words: 2,
          separator: "-"
        )

      password = ExkPasswd.generate(config)
      assert is_binary(password)
      assert password =~ "-"
    end
  end

  describe "transform entropy accumulation" do
    test "entropy from multiple random transforms accumulates" do
      config = Config.new!(num_words: 3)

      transforms = [
        %CaseTransform{mode: :random},
        %Substitution{map: %{"e" => "3"}, mode: :random}
      ]

      total_entropy =
        Enum.reduce(transforms, 0.0, fn t, acc ->
          acc + Transform.entropy_bits(t, config)
        end)

      # Each random transform adds 1 bit per word = 3 bits each = 6 total
      assert total_entropy == 6.0
    end

    test "mixed deterministic and random transforms" do
      config = Config.new!(num_words: 4)

      transforms = [
        %CaseTransform{mode: :upper},
        %Substitution{map: %{"e" => "3"}, mode: :random},
        %CaseTransform{mode: :none}
      ]

      total_entropy =
        Enum.reduce(transforms, 0.0, fn t, acc ->
          acc + Transform.entropy_bits(t, config)
        end)

      # Only the random substitution adds entropy: 4 bits
      assert total_entropy == 4.0
    end
  end

  describe "edge cases" do
    setup do
      {:ok, config: Config.new!(num_words: 2)}
    end

    test "transform with empty string", %{config: config} do
      transform = %CaseTransform{mode: :upper}
      assert Transform.apply(transform, "", config) == ""
    end

    test "transform preserves string length for case transforms", %{config: config} do
      word = "hello"

      for mode <- [:upper, :lower, :capitalize, :invert, :none, :random] do
        transform = %CaseTransform{mode: mode}
        result = Transform.apply(transform, word, config)

        assert String.length(result) == String.length(word),
               "Mode #{mode} changed string length"
      end
    end

    test "substitution with no matching characters", %{config: config} do
      transform = %Substitution{map: %{"x" => "y"}, mode: :always}
      assert Transform.apply(transform, "hello", config) == "hello"
    end

    test "substitution handles mixed case matching", %{config: config} do
      # Substitution matches lowercase version of character
      transform = %Substitution{map: %{"e" => "3"}, mode: :always}
      assert Transform.apply(transform, "HELLO", config) == "H3LLO"
      assert Transform.apply(transform, "Hello", config) == "H3llo"
    end

    test "Pinyin transform with non-Chinese text", %{config: config} do
      transform = %Pinyin{}
      # Non-Chinese text passes through unchanged
      assert Transform.apply(transform, "hello", config) == "hello"
    end

    test "Romaji transform with non-Japanese text", %{config: config} do
      transform = %Romaji{}
      # Non-Japanese text passes through unchanged
      assert Transform.apply(transform, "hello", config) == "hello"
    end
  end

  describe "integration with password generation" do
    test "transforms affect generated passwords" do
      # Config without transforms
      config_plain =
        Config.new!(
          num_words: 3,
          separator: "-",
          digits: {0, 0},
          padding: %{char: "", before: 0, after: 0, to_length: 0},
          case_transform: :lower
        )

      # Config with substitution transform
      config_transformed =
        Config.new!(
          num_words: 3,
          separator: "-",
          digits: {0, 0},
          padding: %{char: "", before: 0, after: 0, to_length: 0},
          case_transform: :lower,
          meta: %{
            transforms: [
              %Substitution{
                map: %{"a" => "@", "e" => "3", "i" => "1", "o" => "0"},
                mode: :always
              }
            ]
          }
        )

      # Generate multiple passwords from each
      plain_passwords = for _ <- 1..20, do: ExkPasswd.generate(config_plain)
      transformed_passwords = for _ <- 1..20, do: ExkPasswd.generate(config_transformed)

      # Transformed passwords should contain substitution characters
      substitution_chars = ["@", "3", "1", "0"]

      has_substitutions =
        Enum.any?(transformed_passwords, fn pwd ->
          Enum.any?(substitution_chars, &String.contains?(pwd, &1))
        end)

      assert has_substitutions,
             "Expected some transformed passwords to contain substitution characters"

      # Plain passwords should not contain these specific substitution patterns
      # (though they might contain digits from the number 0-9 in other contexts)
      plain_has_at = Enum.any?(plain_passwords, &String.contains?(&1, "@"))
      refute plain_has_at, "Plain passwords shouldn't contain @ symbol"
    end
  end
end
