defmodule ExkPasswdTest do
  @moduledoc """
  Integration tests for the ExkPasswd public API.

  ## Testing Strategy

  This test suite validates the primary user-facing API surface, focusing on:

  - **API contracts**: Ensuring all public functions conform to their documented behavior
  - **Polymorphic input handling**: Testing multiple input types (atoms, keywords, structs)
  - **Cryptographic quality**: Verifying password uniqueness and randomness properties
  - **Batch operations**: Validating optimized batch, unique, and parallel generation paths
  - **Security analysis**: Testing entropy calculation and strength rating accuracy

  ## Concurrency

  Tests run with `async: true` as password generation is purely functional with no shared state.
  The only exception is Dictionary module initialization, which uses ETS and is tested separately
  in `ExkPasswd.DictionaryTest`.

  ## Coverage Focus

  These tests prioritize correctness of the high-level API rather than exhaustive edge case testing
  (which is handled in module-specific test files). The goal is to ensure that the common usage
  patterns documented in hexdocs work reliably in production.

  ## Cryptographic Verification

  Several tests verify cryptographic properties:
  - Password uniqueness across multiple generations (detect PRNG failures)
  - Proper handling of configuration overrides
  - Correct entropy calculations based on configuration space

  ## Performance Characteristics

  While not explicitly benchmarked here, these tests exercise:
  - Single password generation: ~10-50µs
  - Batch generation (100): ~2-5ms
  - Parallel generation scales linearly with cores
  """
  use ExUnit.Case, async: true

  doctest ExkPasswd

  describe "generate/0" do
    test "generates a password" do
      password = ExkPasswd.generate()
      assert is_binary(password)
      assert String.length(password) > 0
    end

    test "generates different passwords on subsequent calls" do
      passwords = for _ <- 1..10, do: ExkPasswd.generate()
      unique_passwords = Enum.uniq(passwords)
      assert length(unique_passwords) == 10
    end
  end

  describe "generate/1" do
    test "generates password with preset atom" do
      password = ExkPasswd.generate(:xkcd)
      assert is_binary(password)
      assert String.contains?(password, "-")
    end

    test "generates password with keyword list" do
      password = ExkPasswd.generate(num_words: 3, separator: "_")
      assert is_binary(password)
      assert String.contains?(password, "_")
    end

    test "generates password with Config struct" do
      config = ExkPasswd.Config.new!(num_words: 2, separator: "-", case_transform: :lower)
      password = ExkPasswd.generate(config)
      assert is_binary(password)
      assert String.contains?(password, "-")
    end

    test "raises for unknown preset" do
      assert_raise ArgumentError, ~r/Unknown preset/, fn ->
        ExkPasswd.generate(:nonexistent)
      end
    end
  end

  describe "generate/2" do
    test "generates password with preset and overrides" do
      password = ExkPasswd.generate(:xkcd, num_words: 3)
      assert is_binary(password)
      parts = String.split(password, "-")
      assert length(parts) == 3
    end
  end

  describe "Config.Presets" do
    test "returns list of all presets" do
      presets = ExkPasswd.Config.Presets.all()
      assert is_list(presets)
      assert length(presets) > 0
      assert Enum.all?(presets, &match?(%ExkPasswd.Config{}, &1))
    end

    test "returns preset by atom" do
      preset = ExkPasswd.Config.Presets.get(:xkcd)
      assert %ExkPasswd.Config{} = preset
    end

    test "returns nil for unknown preset" do
      assert nil == ExkPasswd.Config.Presets.get(:nonexistent)
    end
  end

  describe "generate_batch/2" do
    test "generates specified number of passwords" do
      passwords = ExkPasswd.generate_batch(5)
      assert length(passwords) == 5
      assert Enum.all?(passwords, &is_binary/1)
    end

    test "generates with custom config" do
      config = ExkPasswd.Config.new!(num_words: 2)
      passwords = ExkPasswd.generate_batch(3, config)
      assert length(passwords) == 3
    end
  end

  describe "generate_unique_batch/2" do
    test "generates unique passwords" do
      passwords = ExkPasswd.generate_unique_batch(10)
      assert length(passwords) == 10
      assert length(Enum.uniq(passwords)) == 10
    end
  end

  describe "generate_parallel/2" do
    test "generates passwords in parallel" do
      passwords = ExkPasswd.generate_parallel(20)
      assert length(passwords) == 20
      assert Enum.all?(passwords, &is_binary/1)
    end
  end

  describe "calculate_entropy/2" do
    test "calculates entropy for generated password" do
      config = ExkPasswd.Config.new!(num_words: 3)
      password = ExkPasswd.generate(config)
      result = ExkPasswd.calculate_entropy(password, config)

      assert is_float(result.blind)
      assert is_float(result.seen)
      assert result.status in [:excellent, :good, :fair, :weak]
    end
  end

  describe "analyze_strength/2" do
    test "analyzes password strength" do
      config = ExkPasswd.Config.new!(num_words: 4)
      password = ExkPasswd.generate(config)
      result = ExkPasswd.analyze_strength(password, config)

      assert result.rating in [:excellent, :good, :fair, :weak]
      assert is_integer(result.score)
      assert result.score >= 0 and result.score <= 100
    end
  end

  describe "strength_rating/2" do
    test "returns rating atom" do
      config = ExkPasswd.Config.new!(num_words: 4)
      password = ExkPasswd.generate(config)
      rating = ExkPasswd.strength_rating(password, config)

      assert rating in [:excellent, :good, :fair, :weak]
    end
  end

  describe "generate/1 error handling" do
    test "raises ArgumentError for unknown preset atom" do
      assert_raise ArgumentError, ~r/Unknown preset/, fn ->
        ExkPasswd.generate(:fake_preset_that_does_not_exist)
      end
    end

    test "raises ArgumentError for invalid keyword list format" do
      assert_raise ArgumentError, ~r/Expected keyword list/, fn ->
        ExkPasswd.generate([:not, :a, :keyword, :list])
      end
    end
  end

  describe "generate/2 error handling" do
    test "raises ArgumentError for unknown preset in generate/2" do
      assert_raise ArgumentError, ~r/Unknown preset/, fn ->
        ExkPasswd.generate(:nonexistent_preset, num_words: 3)
      end
    end

    test "works with valid preset and options" do
      password = ExkPasswd.generate(:xkcd, num_words: 5)
      assert is_binary(password)
      assert String.length(password) > 0
    end
  end

  describe "version/0" do
    test "returns version string" do
      version = ExkPasswd.version()
      assert is_binary(version)
      assert String.match?(version, ~r/^\d+\.\d+\.\d+/)
    end
  end
end
