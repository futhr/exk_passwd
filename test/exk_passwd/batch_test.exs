defmodule ExkPasswd.BatchTest do
  @moduledoc false

  use ExUnit.Case, async: false
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

    test "caps workers at the password count" do
      config = Config.new!(num_words: 2)
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
    test "accepts success on the last permitted attempt" do
      assert [_] = Batch.generate_unique_batch(1, Config.new!(), max_attempts: 1)
    end

    test "stops at the attempt budget when the output space is exhausted" do
      ExkPasswd.Dictionary.load_custom(:single_batch_word, ["test"])
      on_exit(fn -> ExkPasswd.Dictionary.delete_custom(:single_batch_word) end)

      config =
        Config.new!(
          dictionary: :single_batch_word,
          num_words: 1,
          case_transform: :none,
          separator: "",
          digits: {0, 0},
          padding: %{char: "", before: 0, after: 0}
        )

      assert_raise RuntimeError, ~r/after 2 attempts/, fn ->
        Batch.generate_unique_batch(2, config, max_attempts: 2)
      end
    end

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

    test "refills the fixed default buffer for larger batches" do
      config = Config.new!(num_words: 2)
      passwords = Batch.generate_batch(150, config)
      assert length(passwords) == 150
      assert Enum.all?(passwords, &is_binary/1)
    end

    test "uses default buffer size for small batches" do
      config = Config.new!(num_words: 2)
      passwords = Batch.generate_batch(5, config)
      assert length(passwords) == 5
      assert Enum.all?(passwords, &is_binary/1)
    end

    test "supports very small buffers" do
      config = Config.new!(num_words: 2)
      assert length(Batch.generate_batch(3, config, buffer_size: 1)) == 3
    end

    test "rejects invalid counts and options" do
      config = Config.new!()

      assert_raise ArgumentError, fn -> Batch.generate_batch(-1, config) end
      assert_raise ArgumentError, fn -> Batch.generate_parallel(1, config, workers: 0) end

      assert_raise ArgumentError, fn ->
        apply(Batch, :generate_batch, [1, config, %{buffer_size: 10}])
      end

      assert_raise ArgumentError, fn -> Batch.generate_batch(1, config, unknown: true) end

      assert_raise ArgumentError, fn ->
        Batch.generate_unique_batch(1, config, max_attempts: 0)
      end
    end

    test "returns an empty list for zero count" do
      config = Config.new!()

      assert Batch.generate_batch(0, config) == []
      assert Batch.generate_unique_batch(0, config) == []
      assert Batch.generate_parallel(0, config) == []
    end
  end
end
