defmodule ExkPasswd.Random do
  @moduledoc """
  Cryptographically secure random number generation utilities.

  This module provides secure random selection and generation functions using
  `:crypto.strong_rand_bytes/1` to ensure all randomness is cryptographically
  secure and suitable for password generation.

  ## Security

  **NEVER use `:rand` module or `Enum.random/1` for password generation.**
  These functions use predictable pseudo-random number generators that are
  NOT suitable for security-critical applications.

  All functions in this module use `:crypto.strong_rand_bytes/1` which provides
  cryptographically secure randomness backed by the operating system's secure
  random number generator.

  ## Examples

      iex> value = ExkPasswd.Random.select([1, 2, 3, 4, 5])
      ...> value in [1, 2, 3, 4, 5]
      true

      iex> n = ExkPasswd.Random.integer(100)
      ...> n >= 0 and n < 100
      true

      iex> is_boolean(ExkPasswd.Random.boolean())
      true
  """

  @doc """
  Generates a cryptographically secure random integer between 0 and max-1.

  Uses `:crypto.strong_rand_bytes/1` with **rejection sampling** to eliminate
  modulo bias and ensure uniform distribution.

  ## Security

  This function uses rejection sampling to avoid modulo bias. When `max` doesn't
  evenly divide 2^32, naive modulo creates statistical bias where some values
  appear more frequently. This implementation rejects biased values and retries.

  **Performance**: Rejection rate is ~(max/2^32), negligible for all practical values.

  ## Parameters

  - `max` - Upper bound (exclusive). Must be a positive integer.

  ## Returns

  A random integer `n` where `0 <= n < max`.

  ## Examples

      iex> n = ExkPasswd.Random.integer(10)
      ...> n >= 0 and n < 10
      true

      iex> n = ExkPasswd.Random.integer(1)
      ...> n
      0
  """
  @spec integer(pos_integer()) :: non_neg_integer()
  def integer(max) when is_integer(max) and max > 0 do
    # Use rejection sampling to eliminate modulo bias
    # Calculate the largest value that gives us a complete set of max-sized ranges
    # 2^32
    range_size = 0x1_0000_0000
    threshold = range_size - rem(range_size, max)

    # Generate unbiased random value
    integer_unbiased(max, threshold)
  end

  # Private helper for rejection sampling
  defp integer_unbiased(max, threshold) do
    value = :crypto.strong_rand_bytes(4) |> :binary.decode_unsigned()

    if value < threshold do
      # Value is in unbiased range - accept it
      rem(value, max)
    else
      # Value is in biased range - reject and retry
      # This happens rarely: probability = (max / 2^32)
      integer_unbiased(max, threshold)
    end
  end

  @doc """
  Securely selects a random element from an enumerable.

  Returns `nil` if the enumerable is empty.

  ## Parameters

  - `enumerable` - Any enumerable (list, range, etc.)

  ## Returns

  A randomly selected element, or `nil` if empty.

  ## Examples

      iex> value = ExkPasswd.Random.select([1, 2, 3])
      ...> value in [1, 2, 3]
      true

      iex> ExkPasswd.Random.select([])
      nil

      iex> value = ExkPasswd.Random.select(1..5)
      ...> value in 1..5
      true
  """
  @spec select(Enum.t()) :: any() | nil
  def select(enumerable) do
    list = Enum.to_list(enumerable)

    case length(list) do
      0 -> nil
      count -> Enum.at(list, integer(count))
    end
  end

  @doc """
  Generates a cryptographically secure random boolean.

  ## Returns

  `true` or `false` with equal probability.

  ## Examples

      iex> is_boolean(ExkPasswd.Random.boolean())
      true
  """
  @spec boolean() :: boolean()
  def boolean do
    integer(2) == 1
  end

  @doc """
  Generates a cryptographically secure random integer in a range.

  ## Parameters

  - `min` - Lower bound (inclusive)
  - `max` - Upper bound (inclusive)

  ## Returns

  A random integer `n` where `min <= n <= max`.

  ## Examples

      iex> n = ExkPasswd.Random.integer_between(5, 10)
      ...> n >= 5 and n <= 10
      true

      iex> ExkPasswd.Random.integer_between(7, 7)
      7
  """
  @spec integer_between(integer(), integer()) :: integer()
  def integer_between(min, max) when min <= max do
    min + integer(max - min + 1)
  end

  def integer_between(max, min), do: integer_between(min, max)
end
