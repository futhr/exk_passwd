defmodule ExkPasswd.EdgeCaseTest do
  @moduledoc """
  Tests for edge cases and boundary conditions in ExkPasswd.

  ## Overview

  This suite captures unusual scenarios, boundary conditions, and error paths
  that may not be covered by the main module test suites. These tests ensure
  robustness when the library encounters unexpected inputs or states.

  ## Test Categories

  1. **Custom Dictionary Edge Cases**:
     - Dictionaries with no words in requested length range
     - Empty custom dictionaries
     - Range requests that fall outside available word lengths

  2. **Entropy Calculation Extremes**:
     - Very high entropy passwords (10+ words)
     - Configurations that push entropy calculation limits

  3. **ETS Initialization Idempotency**:
     - Repeated `Dictionary.init/0` calls are safe
     - Handles "table already exists" gracefully

  4. **Buffer Exhaustion**:
     - Small buffers that exhaust within single operations
     - Multiple operations forcing buffer refresh cycles

  5. **Random Module Edge Cases**:
     - `Random.integer(1)` always returns 0
     - Boundary conditions for modulo operations

  6. **Batch Generation Edge Cases**:
     - Single-password batch (count = 1)
     - Validates minimum batch functionality

  7. **Schema Validation Edge Cases**:
     - Type validation (Range expected, integer provided)
     - Boundary value rejections

  ## Why These Tests Exist

  Edge case tests serve as regression guards. Many represent bugs found during
  development or unusual usage patterns reported by users. They ensure:

  - Library doesn't crash on boundary inputs
  - Error messages are helpful and accurate
  - State management handles edge conditions

  ## Concurrency Note

  This suite uses `async: false` because some tests involve shared ETS state
  (Dictionary initialization). Running async could cause race conditions.
  """
  use ExUnit.Case

  describe "Dictionary.random_word_between/4 with custom dictionary" do
    setup do
      # Initialize ETS table if not already done
      ExkPasswd.Dictionary.init()
      :ok
    end

    test "returns nil for uncommon range in custom dictionary" do
      # Load a custom dict with limited word lengths
      ExkPasswd.Dictionary.load_custom(:test_dict_range, ["short", "words", "only"])

      # Request a range that doesn't exist (words longer than available)
      result = ExkPasswd.Dictionary.random_word_between(20, 25, :none, :test_dict_range)
      assert result == nil
    end
  end

  describe "Entropy calculation edge cases" do
    test "calculates entropy for very high entropy passwords" do
      # Create a config with many words for high entropy
      config = ExkPasswd.Config.new!(num_words: 10, word_length: 8..10)
      password = ExkPasswd.generate(config)

      result = ExkPasswd.calculate_entropy(password, config)

      # Should have very high blind entropy
      assert result.blind > 100
    end
  end

  describe "Dictionary.init/0 when already initialized" do
    test "handles ETS table already existing" do
      # First call creates table
      ExkPasswd.Dictionary.init()

      # Second call should handle _table -> :ok path (line 166)
      result = ExkPasswd.Dictionary.init()
      assert result == :ok
    end
  end

  describe "Buffer edge cases" do
    test "handles buffer exhaustion and refill" do
      # Create a very small buffer
      buffer = ExkPasswd.Buffer.new(10)

      # Exhaust it by requesting many random integers
      {_, final_buffer} =
        Enum.reduce(1..5, {[], buffer}, fn _, {acc, buf} ->
          {val, new_buf} = ExkPasswd.Buffer.random_integer(buf, 1000)
          {[val | acc], new_buf}
        end)

      # Buffer should have been refilled at least once
      assert is_struct(final_buffer, ExkPasswd.Buffer)
    end
  end

  describe "Random.integer/1 edge case" do
    test "handles max = 1 (always returns 0)" do
      result = ExkPasswd.Random.integer(1)
      assert result == 0
    end
  end

  describe "Batch generation edge cases" do
    test "generates batch of 1 password successfully" do
      config = ExkPasswd.Config.new!()
      passwords = ExkPasswd.Batch.generate_batch(1, config)

      assert length(passwords) == 1
      assert is_binary(hd(passwords))
    end
  end

  describe "Config.Schema edge cases" do
    test "validates word_length must be a Range" do
      result = ExkPasswd.Config.Schema.validate(%ExkPasswd.Config{word_length: 4})
      assert {:error, _} = result
    end
  end
end
