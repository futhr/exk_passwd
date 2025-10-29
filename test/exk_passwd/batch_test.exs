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

    test "passwords are unique" do
      config = Config.new!(num_words: 4)
      passwords = Batch.generate_parallel(20, config)
      unique = Enum.uniq(passwords)
      assert length(unique) == length(passwords)
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
  end
end
