defmodule ExkPasswd.BatchTest do
  @moduledoc """
  Tests for ExkPasswd.Batch - optimized batch password generation.

  ## Test Strategy

  This suite validates the three batch generation strategies:

  1. **`generate_batch/3`**: Sequential generation with buffered random state
     - Reduces `:crypto.strong_rand_bytes/1` syscalls via pre-allocated buffer
     - Best for moderate batch sizes (10-1000 passwords)

  2. **`generate_unique_batch/3`**: Guaranteed unique passwords
     - Uses MapSet tracking to detect and regenerate duplicates
     - Fails fast when entropy is too low to generate unique passwords

  3. **`generate_parallel/3`**: Multi-process generation
     - Distributes work across `System.schedulers_online()` workers
     - Best for large batches (1000+) on multi-core systems

  ## Performance Characteristics

  - Buffered generation: ~2-3x faster than individual `Password.create/1` calls
  - Parallel generation: Scales linearly with available CPU cores
  - Unique generation: O(n) best case, O(n * max_attempts) worst case

  ## Concurrency Model

  Tests use `async: true` because batch operations are stateless:
  - Each batch creates its own Buffer state
  - No shared mutable state between tests
  - Parallel generation uses isolated Task processes
  """
  use ExUnit.Case, async: true
  doctest ExkPasswd.Batch

  alias ExkPasswd.{Batch, Config}

  describe "generate_parallel/3" do
    test "generates requested number of passwords" do
      config = Config.new!(num_words: 3)
      passwords = Batch.generate_parallel(10, config)
      assert length(passwords) == 10
      assert Enum.all?(passwords, &is_binary/1)
    end

    test "handles more workers than passwords" do
      config = Config.new!(num_words: 2)
      passwords = Batch.generate_parallel(2, config, workers: 100)
      assert length(passwords) == 2
      assert Enum.all?(passwords, &is_binary/1)
    end

    test "handles 1 password with many workers" do
      config = Config.new!(num_words: 2)
      passwords = Batch.generate_parallel(1, config, workers: 50)
      assert length(passwords) == 1
      assert is_binary(hd(passwords))
    end

    test "handles zero passwords edge case" do
      config = Config.new!(num_words: 2)
      passwords = Batch.generate_parallel(0, config, workers: 4)
      assert passwords == []
    end

    test "passwords are unique" do
      config = Config.new!(num_words: 4)
      passwords = Batch.generate_parallel(20, config)
      unique = Enum.uniq(passwords)
      assert length(unique) == length(passwords)
    end

    test "handles workers with zero batch_size due to division" do
      config = Config.new!(num_words: 2)
      # 3 passwords with 10 workers: workers 0-2 get 1 each, workers 3-9 get 0
      # This triggers the batch_size == 0 else branch
      passwords = Batch.generate_parallel(3, config, workers: 10)
      assert length(passwords) == 3
      assert Enum.all?(passwords, &is_binary/1)
    end

    test "distributes work correctly with remainder" do
      config = Config.new!(num_words: 2)
      # 7 passwords with 3 workers: workers get [3, 3, 1] or [3, 2, 2]
      passwords = Batch.generate_parallel(7, config, workers: 3)
      assert length(passwords) == 7
    end

    test "uses default workers count" do
      config = Config.new!(num_words: 2)
      passwords = Batch.generate_parallel(5, config)
      assert length(passwords) == 5
    end
  end

  describe "generate_unique_batch/3" do
    test "generates unique passwords" do
      config = Config.new!(num_words: 3)
      passwords = Batch.generate_unique_batch(15, config)
      assert length(passwords) == 15
      unique = Enum.uniq(passwords)
      assert length(unique) == 15
    end

    test "raises when impossible to generate unique passwords" do
      config =
        Config.new!(
          num_words: 1,
          word_length: 4..4,
          separator: "",
          digits: {0, 0},
          padding: %{char: "", before: 0, after: 0, to_length: 0}
        )

      assert_raise RuntimeError, ~r/Failed to generate/, fn ->
        Batch.generate_unique_batch(10000, config, max_attempts: 1)
      end
    end

    test "generates correct number with low entropy config" do
      config =
        Config.new!(
          num_words: 2,
          word_length: 4..4,
          separator: "",
          digits: {0, 0},
          padding: %{char: "", before: 0, after: 0, to_length: 0},
          case_transform: :lower
        )

      passwords = Batch.generate_unique_batch(3, config)
      assert length(passwords) == 3
      assert length(Enum.uniq(passwords)) == 3
    end

    test "handles collisions during unique generation" do
      # Use single-word dictionary to guarantee collisions
      # Only 1 possible password means every attempt after first is collision
      ExkPasswd.Dictionary.init()
      ExkPasswd.Dictionary.load_custom(:single_word, ["test"])

      config =
        Config.new!(
          num_words: 1,
          word_length: 4..4,
          word_length_bounds: 1..10,
          separator: "",
          digits: {0, 0},
          padding: %{char: "", before: 0, after: 0, to_length: 0},
          case_transform: :lower,
          dictionary: :single_word
        )

      # Request 2 unique from only 1 possible - guaranteed to hit collision branch
      # Will exhaust max_attempts and raise since only 1 unique is possible
      assert_raise RuntimeError, ~r/Failed to generate 2 unique passwords/, fn ->
        Batch.generate_unique_batch(2, config, max_attempts: 5)
      end
    end
  end

  describe "generate_batch/3" do
    test "generates specified number of passwords" do
      config = Config.new!(num_words: 2)
      passwords = Batch.generate_batch(20, config)
      assert length(passwords) == 20
      assert Enum.all?(passwords, &is_binary/1)
    end

    test "handles custom buffer size" do
      config = Config.new!(num_words: 2)
      passwords = Batch.generate_batch(10, config, buffer_size: 5000)
      assert length(passwords) == 10
    end

    test "handles default buffer size calculation" do
      config = Config.new!(num_words: 2)
      # When count * 100 > 10000, it should use count * 100
      passwords = Batch.generate_batch(150, config)
      assert length(passwords) == 150
      assert Enum.all?(passwords, &is_binary/1)
    end

    test "uses default buffer size for small batches" do
      config = Config.new!(num_words: 2)
      # When count * 100 < 10000, it should use 10000
      passwords = Batch.generate_batch(5, config)
      assert length(passwords) == 5
      assert Enum.all?(passwords, &is_binary/1)
    end
  end
end
