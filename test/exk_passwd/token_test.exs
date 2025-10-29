defmodule ExkPasswd.TokenTest do
  @moduledoc """
  Tests for ExkPasswd.Token - random token generation functions.
  """
  use ExUnit.Case, async: true
  doctest ExkPasswd.Token

  alias ExkPasswd.{Buffer, Token}

  describe "get_word/1" do
    test "returns word of specified length" do
      word = Token.get_word(5)
      assert String.length(word) == 5
    end

    test "returns empty string for zero length" do
      assert Token.get_word(0) == ""
    end

    test "returns empty string for negative length" do
      assert Token.get_word(-5) == ""
    end

    test "returns empty string for very long length" do
      # No words this long exist
      assert Token.get_word(100) == ""
    end

    test "returns empty string for invalid input" do
      assert Token.get_word("invalid") == ""
      assert Token.get_word(nil) == ""
      assert Token.get_word(3.14) == ""
    end
  end

  describe "get_word_between/2" do
    test "returns word within range" do
      word = Token.get_word_between(4, 8)
      len = String.length(word)
      assert len >= 4 and len <= 8
    end

    test "handles reversed arguments" do
      word = Token.get_word_between(8, 4)
      len = String.length(word)
      assert len >= 4 and len <= 8
    end

    test "handles equal min and max" do
      word = Token.get_word_between(5, 5)
      assert String.length(word) == 5
    end

    test "returns empty string for negative range" do
      assert Token.get_word_between(-10, 3) == ""
    end

    test "returns empty string for both negative" do
      assert Token.get_word_between(-5, -2) == ""
    end

    test "returns empty string for zero range" do
      assert Token.get_word_between(0, 5) == ""
    end

    test "returns empty string for invalid input" do
      assert Token.get_word_between("a", "b") == ""
      assert Token.get_word_between(nil, 5) == ""
      assert Token.get_word_between(5, nil) == ""
    end
  end

  describe "get_number/1" do
    test "returns number with correct length" do
      num = Token.get_number(3)
      assert String.length(num) == 3
      assert String.match?(num, ~r/^\d{3}$/)
    end

    test "returns zero-padded numbers" do
      # Run multiple times to ensure padding works
      for _ <- 1..10 do
        num = Token.get_number(5)
        assert String.length(num) == 5
        assert String.match?(num, ~r/^\d{5}$/)
      end
    end

    test "returns empty string for zero digits" do
      assert Token.get_number(0) == ""
    end

    test "returns empty string for negative digits" do
      assert Token.get_number(-1) == ""
      assert Token.get_number(-10) == ""
    end

    test "returns empty string for invalid input" do
      assert Token.get_number("invalid") == ""
      assert Token.get_number(nil) == ""
      assert Token.get_number(3.14) == ""
    end
  end

  describe "get_token/1 with string" do
    test "returns single character from string" do
      token = Token.get_token("abc")
      assert token in ["a", "b", "c"]
    end

    test "returns same character for single char string" do
      assert Token.get_token("-") == "-"
      assert Token.get_token("!") == "!"
    end

    test "returns empty string for empty input" do
      assert Token.get_token("") == ""
    end

    test "handles symbols" do
      token = Token.get_token("!@#$%")
      assert String.contains?("!@#$%", token)
      assert String.length(token) == 1
    end
  end

  describe "get_token/1 with list" do
    test "returns element from list" do
      token = Token.get_token(["!", "@", "#"])
      assert token in ["!", "@", "#"]
    end

    test "returns single element from single-item list" do
      assert Token.get_token(["x"]) == "x"
    end

    test "returns empty string for empty list" do
      assert Token.get_token([]) == ""
    end

    test "works with word lists" do
      token = Token.get_token(~w[alpha beta gamma])
      assert token in ~w[alpha beta gamma]
    end
  end

  describe "get_n_of/2" do
    test "repeats character n times" do
      result = Token.get_n_of("!", 5)
      assert result == "!!!!!"
    end

    test "works with multiple char options" do
      result = Token.get_n_of("!@#", 3)
      assert String.length(result) == 3
      # All chars should be the same
      [first | rest] = String.graphemes(result)
      assert Enum.all?(rest, &(&1 == first))
      # The character should be from the set
      assert first in ["!", "@", "#"]
    end

    test "works with list input" do
      result = Token.get_n_of(~w[! @ #], 4)
      assert String.length(result) == 4
      # All chars should be the same
      [first | rest] = String.graphemes(result)
      assert Enum.all?(rest, &(&1 == first))
    end

    test "returns empty string for zero count" do
      assert Token.get_n_of("!", 0) == ""
    end

    test "returns empty string for negative count" do
      assert Token.get_n_of("!", -5) == ""
    end

    test "returns empty string for empty range" do
      assert Token.get_n_of("", 3) == ""
      assert Token.get_n_of([], 3) == ""
    end

    test "returns empty string for invalid input" do
      assert Token.get_n_of("!", "invalid") == ""
      assert Token.get_n_of("!", nil) == ""
    end
  end

  describe "get_number_with_state/2" do
    test "returns number and new state" do
      state = Buffer.new(100)
      {num, new_state} = Token.get_number_with_state(3, state)

      assert String.length(num) == 3
      assert String.match?(num, ~r/^\d{3}$/)
      assert %Buffer{} = new_state
      assert new_state != state
    end

    test "returns empty string and state for zero digits" do
      state = Buffer.new(100)
      {num, new_state} = Token.get_number_with_state(0, state)

      assert num == ""
      assert new_state == state
    end

    test "returns empty string and state for negative digits" do
      state = Buffer.new(100)
      {num, new_state} = Token.get_number_with_state(-1, state)

      assert num == ""
      assert new_state == state
    end

    test "can generate multiple numbers from same state" do
      state = Buffer.new(1000)

      {num1, state} = Token.get_number_with_state(2, state)
      {num2, state} = Token.get_number_with_state(3, state)
      {num3, _state} = Token.get_number_with_state(4, state)

      assert String.length(num1) == 2
      assert String.length(num2) == 3
      assert String.length(num3) == 4
    end

    test "returns empty string for invalid digits input" do
      state = Buffer.new(100)
      {num, new_state} = Token.get_number_with_state("invalid", state)

      assert num == ""
      assert new_state == state
    end
  end

  describe "randomness quality" do
    test "get_word generates different words" do
      words = for _ <- 1..20, do: Token.get_word(5)
      unique_count = Enum.uniq(words) |> length()
      # Should have some variety (at least 5 different words out of 20)
      assert unique_count >= 5
    end

    test "get_number generates different numbers" do
      numbers = for _ <- 1..20, do: Token.get_number(3)
      unique_count = Enum.uniq(numbers) |> length()
      # Should have some variety
      assert unique_count >= 10
    end

    test "get_token has variety" do
      tokens = for _ <- 1..100, do: Token.get_token("!@#$%")
      unique_count = Enum.uniq(tokens) |> length()
      # Should eventually see multiple different symbols
      assert unique_count >= 3
    end
  end
end
