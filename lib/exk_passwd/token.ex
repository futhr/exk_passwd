defmodule ExkPasswd.Token do
  @moduledoc """
  Provides core functionality for generating random tokens (words, numbers,
  symbols) to be put together to make easy to remember, complex passwords.

  All random generation uses cryptographically secure random number generation
  via `ExkPasswd.Random` to ensure passwords are unpredictable and secure.

  Word selection is delegated to `ExkPasswd.Dictionary` which provides
  optimized compile-time indexed word lookups.

  ## Security

  This module uses `:crypto.strong_rand_bytes/1` for all random operations.
  Never use `Enum.random/1` or the `:rand` module for password generation
  as they are not cryptographically secure.

  ## Examples

      iex> word = ExkPasswd.Token.get_word(4)
      ...> String.length(word)
      4

      iex> word = ExkPasswd.Token.get_word_between(4, 8)
      ...> len = String.length(word)
      ...> len >= 4 and len <= 8
      true

      iex> num = ExkPasswd.Token.get_number(3)
      ...> String.length(num)
      3

      iex> token = ExkPasswd.Token.get_token("!@#$")
      ...> String.contains?("!@#$", token)
      true
  """

  alias ExkPasswd.{Buffer, Dictionary, Random}

  @doc """
  Select a word at random based on the specified length of the word.

  Uses cryptographically secure random selection via `ExkPasswd.Random`.

  Returns an empty string if no words of that length exist or if the
  input is invalid.

  ## Parameters

  - `length` - The exact word length to match. Must be a positive integer.

  ## Returns

  A random word of the specified length, or `""` if none exist.

  ## Examples

      iex> word = ExkPasswd.Token.get_word(4)
      ...> String.length(word)
      4

      iex> ExkPasswd.Token.get_word(-1)
      ""

      iex> ExkPasswd.Token.get_word(100)
      ""
  """
  @spec get_word(integer()) :: String.t()
  def get_word(length) when is_integer(length) and length > 0 do
    Dictionary.random_word_between(length, length, :none, :eff) || ""
  end

  def get_word(_), do: ""

  @doc """
  Select a word at random with length between min and max (inclusive).

  Uses cryptographically secure random selection via `ExkPasswd.Random`.
  Handles arguments in either order.

  Returns an empty string if no words in that range exist or if inputs
  are invalid.

  ## Parameters

  - `first` - Lower or upper bound (inclusive)
  - `last` - Upper or lower bound (inclusive)

  ## Returns

  A random word with length in the specified range, or `""` if none exist.

  ## Examples

      iex> word = ExkPasswd.Token.get_word_between(5, 7)
      ...> len = String.length(word)
      ...> len >= 5 and len <= 7
      true

      iex> word = ExkPasswd.Token.get_word_between(8, 4)
      ...> len = String.length(word)
      ...> len >= 4 and len <= 8
      true

      iex> ExkPasswd.Token.get_word_between(-10, 3)
      ""
  """
  @spec get_word_between(integer(), integer()) :: String.t()
  def get_word_between(last, first)
      when is_integer(last) and is_integer(first) and last > first do
    get_word_between(first, last)
  end

  def get_word_between(length, length) when is_integer(length) do
    get_word(length)
  end

  def get_word_between(first, last) when is_integer(first) and is_integer(last) and first > 0 do
    Dictionary.random_word_between(first, last, :none, :eff) || ""
  end

  def get_word_between(_first, _last), do: ""

  @doc """
  Get a zero-padded random number with a specified number of digits.

  Uses cryptographically secure random number generation.

  Returns an empty string if the input is invalid.

  ## Parameters

  - `digits` - The number of digits. Must be a positive integer.

  ## Returns

  A string containing a zero-padded random number, or `""` if invalid input.

  ## Examples

      iex> num = ExkPasswd.Token.get_number(2)
      ...> String.length(num)
      2
      iex> String.to_integer(num) >= 0
      true
      iex> String.to_integer(num) <= 99
      true

      iex> num = ExkPasswd.Token.get_number(5)
      ...> String.length(num)
      5

      iex> ExkPasswd.Token.get_number(-1)
      ""

      iex> ExkPasswd.Token.get_number(0)
      ""
  """
  @spec get_number(integer()) :: String.t()
  def get_number(digits) when is_integer(digits) and digits >= 1 do
    max = round(:math.pow(10, digits))

    Random.integer(max)
    |> Integer.to_string()
    |> String.pad_leading(digits, "0")
  end

  def get_number(_), do: ""

  @doc """
  Randomly select one character/token from a string or list.

  Uses cryptographically secure random selection.

  If given a string, splits it into graphemes and selects one.
  If given a single-character string, returns that character.
  If given an empty string or list, returns an empty string.

  ## Parameters

  - `string_or_list` - A string to split into graphemes, or a list to select from

  ## Returns

  A randomly selected character/element, or `""` if input is empty.

  ## Examples

      iex> token = ExkPasswd.Token.get_token("-")
      ...> token
      "-"

      iex> ExkPasswd.Token.get_token([])
      ""

      iex> ExkPasswd.Token.get_token("")
      ""

      iex> token = ExkPasswd.Token.get_token("!@#$%")
      ...> String.contains?("!@#$%", token)
      true

      iex> token = ExkPasswd.Token.get_token(~w[! @ # $ %])
      ...> Enum.member?(~w[! @ # $ %], token)
      true
  """
  @spec get_token(String.t() | list()) :: String.t()
  def get_token(string) when is_binary(string) do
    string
    |> String.graphemes()
    |> get_token()
  end

  def get_token(list) when is_list(list) do
    Random.select(list) || ""
  end

  @doc """
  Randomly select a character from the range and repeat it `count` times.

  Uses cryptographically secure random selection.

  ## Parameters

  - `range` - A string or list to select a character from
  - `count` - Number of times to repeat the selected character

  ## Returns

  A string with the selected character repeated `count` times, or `""` if invalid.

  ## Examples

      iex> padding = ExkPasswd.Token.get_n_of("!@#", 3)
      ...> String.length(padding)
      3
      iex> String.at(padding, 0) == String.at(padding, 1)
      true
      iex> String.at(padding, 1) == String.at(padding, 2)
      true

      iex> result = ExkPasswd.Token.get_n_of(~w[! @ #], 5)
      ...> String.length(result)
      5

      iex> ExkPasswd.Token.get_n_of("!@#", 0)
      ""

      iex> ExkPasswd.Token.get_n_of([], 3)
      ""
  """
  @spec get_n_of(String.t() | list(), integer()) :: String.t()
  def get_n_of(range, count) when is_integer(count) and count > 0 do
    char = get_token(range)

    if String.length(char) > 0 do
      String.duplicate(char, count)
    else
      ""
    end
  end

  def get_n_of(_range, _count), do: ""

  @doc """
  Generate a random number string using a stateful Buffer generator.

  This is an optimized version for batch generation that accepts and returns
  a Buffer state, reducing the number of `:crypto.strong_rand_bytes/1`
  syscalls.

  ## Parameters

  - `digits` - Number of digits (1-10)
  - `random_state` - A `Buffer.t()` state

  ## Returns

  A tuple of {number_string, new_random_state}

  ## Examples

      iex> state = ExkPasswd.Buffer.new(1000)
      ...> {num, _new_state} = ExkPasswd.Token.get_number_with_state(3, state)
      ...> String.length(num)
      3
      iex> String.match?(num, ~r/^\\d{3}$/)
      true
  """
  @spec get_number_with_state(non_neg_integer(), Buffer.t()) ::
          {String.t(), Buffer.t()}
  def get_number_with_state(0, random_state), do: {"", random_state}

  def get_number_with_state(digits, random_state) when is_integer(digits) and digits >= 1 do
    max = round(:math.pow(10, digits))

    {value, new_state} = Buffer.random_integer(random_state, max)

    number_string =
      value
      |> Integer.to_string()
      |> String.pad_leading(digits, "0")

    {number_string, new_state}
  end

  def get_number_with_state(_, random_state), do: {"", random_state}
end
