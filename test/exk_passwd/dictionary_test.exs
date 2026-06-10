defmodule ExkPasswd.DictionaryTest do
  @moduledoc false

  use ExUnit.Case, async: false
  doctest ExkPasswd.Dictionary

  alias ExkPasswd.{Buffer, Dictionary}

  describe "init/0" do
    test "remains a safe no-op for backwards compatibility" do
      # Called via apply/3 to avoid the compile-time deprecation warning
      assert apply(Dictionary, :init, []) == :ok
      assert apply(Dictionary, :init, []) == :ok
    end
  end

  describe "custom dictionary storage" do
    test "survives the death of the process that loaded it" do
      Task.async(fn ->
        Dictionary.load_custom(:loaded_by_dead_process, ["uno", "dos", "tres", "cuatro"])
      end)
      |> Task.await()

      word = Dictionary.random_word_between(3, 6, :none, :loaded_by_dead_process)
      assert word in ["uno", "dos", "tres", "cuatro"]
    end

    test "delete_custom/1 removes a loaded dictionary" do
      Dictionary.load_custom(:short_lived, ["uno", "dos", "tres"])
      assert Dictionary.count_between(3, 4, :short_lived) == 3

      assert Dictionary.delete_custom(:short_lived) == :ok
      assert Dictionary.count_between(3, 4, :short_lived) == 0
      assert is_nil(Dictionary.random_word_between(3, 4, :none, :short_lived))
    end

    test "delete_custom/1 is idempotent for unknown dictionaries" do
      assert Dictionary.delete_custom(:was_never_loaded) == :ok
    end

    test "load_custom/2 rejects an empty wordlist" do
      assert_raise ArgumentError, ~r/non-empty list/, fn ->
        Dictionary.load_custom(:invalid_empty, [])
      end
    end

    test "load_custom/2 rejects empty-string and non-string entries" do
      assert_raise ArgumentError, ~r/non-empty strings/, fn ->
        Dictionary.load_custom(:invalid_blank, ["valid", ""])
      end

      assert_raise ArgumentError, ~r/non-empty strings/, fn ->
        Dictionary.load_custom(:invalid_atom_entry, ["valid", :oops])
      end
    end
  end

  describe "empty pre-computed range buckets" do
    test "random_word_between/4 returns nil for a gap range instead of crashing" do
      # No words of length 4 or 5: the {4, 5} bucket is pre-computed but empty
      Dictionary.load_custom(:gap_bucket_dict, ["abc", "abcdefgh"])

      assert is_nil(Dictionary.random_word_between(4, 5, :none, :gap_bucket_dict))
      assert is_nil(Dictionary.random_word_between(4, 5, :capitalize, :gap_bucket_dict))
    end

    test "random_word_between_with_state/5 returns {nil, state} for a gap range" do
      Dictionary.load_custom(:gap_bucket_state_dict, ["abc", "abcdefgh"])
      state = Buffer.new(100)

      assert {nil, ^state} =
               Dictionary.random_word_between_with_state(
                 4,
                 5,
                 :none,
                 :gap_bucket_state_dict,
                 state
               )
    end
  end

  describe "all/0" do
    test "returns list of all words" do
      words = Dictionary.all()
      assert is_list(words)
      assert length(words) > 7000
      assert Enum.all?(words, &is_binary/1)
    end
  end

  describe "size/0" do
    test "returns word count" do
      count = Dictionary.size()
      assert count == 7826
    end
  end

  describe "min_length/0" do
    test "returns minimum word length" do
      min = Dictionary.min_length()
      assert is_integer(min)
      assert min >= 3
    end
  end

  describe "max_length/0" do
    test "returns maximum word length" do
      max = Dictionary.max_length()
      assert is_integer(max)
      assert max <= 10
    end
  end

  describe "count_between/2 with :eff dictionary" do
    test "counts words in valid range" do
      count = Dictionary.count_between(4, 6)
      assert is_integer(count)
      assert count > 0
    end

    test "counts words of exact length" do
      count = Dictionary.count_between(5, 5)
      assert is_integer(count)
      assert count > 0
    end

    test "handles reversed range" do
      count1 = Dictionary.count_between(4, 8)
      count2 = Dictionary.count_between(8, 4)
      assert count1 == count2
    end

    test "returns 0 for invalid range" do
      count = Dictionary.count_between(100, 200)
      assert count == 0
    end
  end

  describe "count_between/3 with custom dictionary" do
    setup do
      custom_words = ["test", "hello", "world", "example", "dictionary"]
      Dictionary.load_custom(:test_dict, custom_words)
      :ok
    end

    test "counts words in custom dictionary" do
      count = Dictionary.count_between(4, 5, :test_dict)
      assert count == 3
    end

    test "handles reversed range in custom dictionary" do
      count1 = Dictionary.count_between(4, 10, :test_dict)
      count2 = Dictionary.count_between(10, 4, :test_dict)
      assert count1 == count2
    end

    test "returns 0 for invalid range in custom dictionary" do
      count = Dictionary.count_between(20, 30, :test_dict)
      assert count == 0
    end
  end

  describe "random_word_between/2 with :none case" do
    test "returns word in valid range" do
      word = Dictionary.random_word_between(4, 8)
      len = String.length(word)
      assert len in 4..8
    end

    test "handles exact length" do
      word = Dictionary.random_word_between(5, 5)
      assert String.length(word) == 5
    end

    test "handles reversed range" do
      word = Dictionary.random_word_between(8, 4)
      len = String.length(word)
      assert len in 4..8
    end

    test "returns different words on multiple calls" do
      words =
        for _ <- 1..20 do
          Dictionary.random_word_between(4, 8)
        end

      unique_words = Enum.uniq(words)
      assert length(unique_words) > 1
    end
  end

  describe "random_word_between/3 with :lower case" do
    test "returns lowercase word" do
      word = Dictionary.random_word_between(4, 8, :lower)
      assert word == String.downcase(word)
      len = String.length(word)
      assert len in 4..8
    end
  end

  describe "random_word_between/3 with :upper case" do
    test "returns uppercase word" do
      word = Dictionary.random_word_between(4, 8, :upper)
      assert word == String.upcase(word)
      len = String.length(word)
      assert len in 4..8
    end
  end

  describe "random_word_between/3 with :capitalize case" do
    test "returns capitalized word" do
      word = Dictionary.random_word_between(4, 8, :capitalize)
      assert word == String.capitalize(word)
      len = String.length(word)
      assert len in 4..8
    end

    test "first character is uppercase" do
      word = Dictionary.random_word_between(5, 7, :capitalize)
      first = String.first(word)
      assert first == String.upcase(first)
    end
  end

  describe "random_word_between/4 with custom dictionary" do
    setup do
      custom_words = ["apple", "banana", "cherry", "date", "elderberry", "fig"]
      Dictionary.load_custom(:fruits, custom_words)
      :ok
    end

    test "returns word from custom dictionary" do
      word = Dictionary.random_word_between(4, 10, :none, :fruits)
      assert word in ["apple", "banana", "cherry", "date", "elderberry", "fig"]
    end

    test "returns lowercase word from custom dictionary" do
      word = Dictionary.random_word_between(4, 6, :lower, :fruits)
      assert word == String.downcase(word)
    end

    test "returns uppercase word from custom dictionary" do
      word = Dictionary.random_word_between(4, 6, :upper, :fruits)
      assert word == String.upcase(word)
    end

    test "returns capitalized word from custom dictionary" do
      word = Dictionary.random_word_between(4, 6, :capitalize, :fruits)
      assert word == String.capitalize(word)
    end
  end

  describe "random_word_between_with_state/5 with :none case" do
    test "returns word and new state" do
      state = Buffer.new(100)
      {word, new_state} = Dictionary.random_word_between_with_state(4, 8, :none, :eff, state)

      assert is_binary(word)
      len = String.length(word)
      assert len in 4..8
      assert %Buffer{} = new_state
    end

    test "handles reversed range" do
      state = Buffer.new(100)
      {word, _} = Dictionary.random_word_between_with_state(8, 4, :none, :eff, state)

      len = String.length(word)
      assert len in 4..8
    end

    test "state is consumed and can be reused" do
      state = Buffer.new(100)
      {word1, state2} = Dictionary.random_word_between_with_state(4, 8, :none, :eff, state)
      {word2, _} = Dictionary.random_word_between_with_state(4, 8, :none, :eff, state2)

      # Both words should be valid
      assert is_binary(word1)
      assert is_binary(word2)
      assert %Buffer{} = state2
    end
  end

  describe "random_word_between_with_state/5 with :lower case" do
    test "returns lowercase word with state" do
      state = Buffer.new(100)
      {word, new_state} = Dictionary.random_word_between_with_state(4, 8, :lower, :eff, state)

      assert word == String.downcase(word)
      assert %Buffer{} = new_state
    end
  end

  describe "random_word_between_with_state/5 with :upper case" do
    test "returns uppercase word with state" do
      state = Buffer.new(100)
      {word, new_state} = Dictionary.random_word_between_with_state(4, 8, :upper, :eff, state)

      assert word == String.upcase(word)
      assert %Buffer{} = new_state
    end
  end

  describe "random_word_between_with_state/5 with :capitalize case" do
    test "returns capitalized word with state" do
      state = Buffer.new(100)

      {word, new_state} =
        Dictionary.random_word_between_with_state(4, 8, :capitalize, :eff, state)

      assert word == String.capitalize(word)
      assert %Buffer{} = new_state
    end
  end

  describe "random_word_between_with_state/5 with custom dictionary" do
    setup do
      custom_words = ["apple", "banana", "cherry"]
      Dictionary.load_custom(:fruits2, custom_words)
      :ok
    end

    test "returns word from custom dictionary with state" do
      state = Buffer.new(100)

      {word, new_state} =
        Dictionary.random_word_between_with_state(5, 6, :none, :fruits2, state)

      assert word in ["apple", "banana", "cherry"]
      assert %Buffer{} = new_state
    end

    test "handles lowercase in custom dictionary with state" do
      state = Buffer.new(100)

      {word, _} =
        Dictionary.random_word_between_with_state(5, 6, :lower, :fruits2, state)

      assert word == String.downcase(word)
    end

    test "handles uppercase in custom dictionary with state" do
      state = Buffer.new(100)

      {word, _} =
        Dictionary.random_word_between_with_state(5, 6, :upper, :fruits2, state)

      assert word == String.upcase(word)
    end

    test "handles capitalize in custom dictionary with state" do
      state = Buffer.new(100)

      {word, _} =
        Dictionary.random_word_between_with_state(5, 6, :capitalize, :fruits2, state)

      assert word == String.capitalize(word)
    end
  end

  describe "load_custom/2" do
    test "loads custom dictionary successfully" do
      words = ["custom1", "custom2", "custom3"]
      result = Dictionary.load_custom(:my_custom, words)
      assert result == :ok
    end

    test "custom dictionary can be used immediately" do
      words = ["test1", "test2", "test3"]
      Dictionary.load_custom(:immediate_test, words)

      word = Dictionary.random_word_between(5, 5, :none, :immediate_test)
      assert word in words
    end

    test "overwrites existing custom dictionary" do
      words1 = ["old1", "old2"]
      words2 = ["new1", "new2", "new3"]

      Dictionary.load_custom(:overwrite_test, words1)
      Dictionary.load_custom(:overwrite_test, words2)

      # Should use new dictionary
      word = Dictionary.random_word_between(4, 4, :none, :overwrite_test)
      assert word in words2
    end

    test "rejects an empty word list" do
      assert_raise ArgumentError, ~r/non-empty list/, fn ->
        Dictionary.load_custom(:empty_dict, [])
      end
    end

    test "stores different case variants" do
      words = ["hello", "world"]
      Dictionary.load_custom(:case_test, words)

      lower = Dictionary.random_word_between(5, 5, :lower, :case_test)
      assert lower == String.downcase(lower)

      upper = Dictionary.random_word_between(5, 5, :upper, :case_test)
      assert upper == String.upcase(upper)
    end
  end

  # Note: Error handling for nonexistent dictionaries is implementation-dependent
  # and may raise ArgumentError from ETS lookup

  describe "performance characteristics" do
    test "can generate many words quickly" do
      {time, _} =
        :timer.tc(fn ->
          for _ <- 1..1000 do
            Dictionary.random_word_between(4, 8)
          end
        end)

      # Should complete in well under 1 second (1_000_000 microseconds)
      assert time < 1_000_000
    end
  end

  describe "count_between/3 edge cases" do
    test "handles reversed arguments" do
      # When max < min, should swap them
      count = Dictionary.count_between(8, 4)
      assert count > 0
    end

    test "handles reversed arguments with custom dictionary" do
      Dictionary.load_custom(:test_reversed, ["short", "medium", "verylongword"])
      count = Dictionary.count_between(10, 4, :test_reversed)
      assert count > 0
    end

    test "returns 0 for non-existent custom dictionary" do
      count = Dictionary.count_between(4, 8, :nonexistent_dict_12345)
      assert count == 0
    end
  end

  describe "random_word_between/4 error handling" do
    test "handles reversed min/max arguments" do
      # Should swap and work correctly
      word = Dictionary.random_word_between(8, 4, :none)
      len = String.length(word)
      assert len in 4..8
    end

    test "returns nil for non-existent custom dictionary" do
      result = Dictionary.random_word_between(4, 8, :none, :nonexistent_custom_dict)
      assert is_nil(result)
    end
  end

  describe "random_word_between_with_state/5 error handling" do
    test "raises for non-existent custom dictionary" do
      state = Buffer.new(100)

      assert_raise ArgumentError, ~r/not found/, fn ->
        Dictionary.random_word_between_with_state(4, 8, :none, :nonexistent_dict, state)
      end
    end

    test "handles reversed min/max with state" do
      state = Buffer.new(100)
      {word, new_state} = Dictionary.random_word_between_with_state(8, 4, :none, :eff, state)

      len = String.length(word)
      assert len in 4..8
      assert %Buffer{} = new_state
    end
  end

  describe "uncommon word length ranges (fallback path)" do
    test "handles range outside pre-computed range for :eff" do
      # Ranges outside 3..10 min/max are not pre-computed
      word = Dictionary.random_word_between(3, 11, :none, :eff)
      # Should use fallback and still return valid word
      assert is_binary(word)
      len = String.length(word)
      assert len in 3..11
    end

    test "handles uncommon range with :lower case" do
      word = Dictionary.random_word_between(2, 12, :lower, :eff)

      if word != nil do
        assert word == String.downcase(word)
      end
    end

    test "handles uncommon range with :upper case" do
      word = Dictionary.random_word_between(2, 12, :upper, :eff)

      if word != nil do
        assert word == String.upcase(word)
      end
    end

    test "handles uncommon range with :capitalize case" do
      word = Dictionary.random_word_between(2, 12, :capitalize, :eff)

      if word != nil do
        assert word == String.capitalize(word)
      end
    end

    test "returns nil for impossible range" do
      # Range far beyond dictionary capabilities
      word = Dictionary.random_word_between(50, 100, :none, :eff)
      assert is_nil(word)
    end
  end

  describe "uncommon word length ranges with state (fallback path)" do
    test "handles uncommon range with state for :none" do
      state = Buffer.new(100)
      {word, new_state} = Dictionary.random_word_between_with_state(2, 11, :none, :eff, state)

      if word != nil do
        assert is_binary(word)
      end

      assert %Buffer{} = new_state
    end

    test "handles uncommon range with state for :lower" do
      state = Buffer.new(100)
      {word, new_state} = Dictionary.random_word_between_with_state(2, 11, :lower, :eff, state)

      if word != nil do
        assert word == String.downcase(word)
      end

      assert %Buffer{} = new_state
    end

    test "handles uncommon range with state for :upper" do
      state = Buffer.new(100)
      {word, new_state} = Dictionary.random_word_between_with_state(2, 11, :upper, :eff, state)

      if word != nil do
        assert word == String.upcase(word)
      end

      assert %Buffer{} = new_state
    end

    test "handles uncommon range with state for :capitalize" do
      state = Buffer.new(100)

      {word, new_state} =
        Dictionary.random_word_between_with_state(2, 11, :capitalize, :eff, state)

      if word != nil do
        assert word == String.capitalize(word)
      end

      assert %Buffer{} = new_state
    end
  end

  describe "custom dictionary with uncommon ranges" do
    setup do
      # Small dictionary for testing edge cases
      Dictionary.load_custom(:tiny_dict, ["hi", "bye"])
      :ok
    end

    test "returns nil for range outside custom dictionary" do
      word = Dictionary.random_word_between(10, 20, :none, :tiny_dict)
      assert is_nil(word)
    end
  end

  describe "load_custom/2 reload" do
    test "reloading a dictionary replaces its contents" do
      Dictionary.load_custom(:reloaded_dict, ["aaa", "bbb"])
      assert Dictionary.count_between(3, 3, :reloaded_dict) == 2

      Dictionary.load_custom(:reloaded_dict, ["cccc"])
      assert Dictionary.count_between(3, 3, :reloaded_dict) == 0
      assert Dictionary.count_between(4, 4, :reloaded_dict) == 1
    end
  end

  describe "custom dictionary with uncommon range fallback" do
    setup do
      # Dictionary with words in unusual length ranges to trigger fallback path
      Dictionary.load_custom(:uncommon_range_dict, [
        "ab",
        "abc",
        "abcd",
        "abcdefghij",
        "abcdefghijk"
      ])

      :ok
    end

    test "triggers fallback for custom dictionary uncommon range" do
      # Range 2..11 is uncommon and should trigger fallback path in count_between_fallback
      count = Dictionary.count_between(2, 11, :uncommon_range_dict)
      assert count == 5
    end

    test "triggers fallback for reversed range in custom dictionary" do
      # Reversed range should also trigger fallback with reversed iteration
      count = Dictionary.count_between(11, 2, :uncommon_range_dict)
      assert count == 5
    end

    test "random_word_between fallback with custom dictionary" do
      # Should trigger random_word_between_custom_fallback
      word = Dictionary.random_word_between(2, 11, :none, :uncommon_range_dict)
      assert word in ["ab", "abc", "abcd", "abcdefghij", "abcdefghijk"]
    end

    test "random_word_between_with_state fallback for custom dictionary uncommon range" do
      state = Buffer.new(100)
      # Range 1..15 triggers fallback path
      {word, new_state} =
        Dictionary.random_word_between_with_state(1, 15, :none, :uncommon_range_dict, state)

      assert word in ["ab", "abc", "abcd", "abcdefghij", "abcdefghijk"]
      assert %Buffer{} = new_state
    end
  end

  describe "count_between_fallback nil branch" do
    setup do
      # Dictionary with wide gaps in word lengths (>10 apart) to trigger fallback path
      # Range {2,15} won't be precomputed since max-min > 10
      Dictionary.load_custom(:wide_sparse_dict, [
        "aa",
        "bbbbb",
        String.duplicate("c", 15)
      ])

      :ok
    end

    test "handles gaps in word lengths via fallback path" do
      # Range 2..15 is NOT precomputed (max-min=13 > 10), triggers count_between_fallback
      # The fallback iterates through lengths 2-15, hitting nil for most lengths
      count = Dictionary.count_between(2, 15, :wide_sparse_dict)
      # Only lengths 2, 5, and 15 have words
      assert count == 3
    end

    test "handles gaps with reversed range" do
      # Also test reversed range fallback
      count = Dictionary.count_between(15, 2, :wide_sparse_dict)
      assert count == 3
    end
  end

  describe "random_word_between_with_state default arguments" do
    test "uses all defaults (3 args)" do
      state = Buffer.new(100)
      # Call with only min, max, and state to use defaults for case_transform and dict
      {word, new_state} = Dictionary.random_word_between_with_state(4, 6, state)

      assert is_binary(word)
      len = String.length(word)
      assert len in 4..6
      assert %Buffer{} = new_state
    end

    test "uses default dictionary (4 args)" do
      state = Buffer.new(100)
      # Call with case_transform but default dict
      {word, new_state} = Dictionary.random_word_between_with_state(4, 6, :lower, state)

      assert is_binary(word)
      assert word == String.downcase(word)
      len = String.length(word)
      assert len in 4..6
      assert %Buffer{} = new_state
    end

    test "uses explicit arguments (5 args)" do
      state = Buffer.new(100)
      {word, new_state} = Dictionary.random_word_between_with_state(4, 6, :upper, :eff, state)

      assert is_binary(word)
      assert word == String.upcase(word)
      len = String.length(word)
      assert len in 4..6
      assert %Buffer{} = new_state
    end
  end
end
