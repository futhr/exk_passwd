defmodule ExkPasswd.BatchTest do
  @moduledoc """
  Tests for ExkPasswd.Batch parallel password generation.
  """
  use ExUnit.Case, async: true

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
