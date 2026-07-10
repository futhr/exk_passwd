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

  This function reads enough bytes to represent the requested range, then uses
  rejection sampling. This avoids the statistical bias introduced by reducing
  every random value with `rem/2`.

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
  def integer(1), do: 0

  def integer(max) when is_integer(max) and max > 0 do
    byte_count = bytes_for(max)
    range_size = Integer.pow(2, byte_count * 8)
    threshold = range_size - rem(range_size, max)

    integer_unbiased(max, threshold, byte_count)
  end

  def integer(max) do
    raise ArgumentError, "max must be a positive integer, got: #{inspect(max)}"
  end

  defp bytes_for(max) do
    max
    |> Kernel.-(1)
    |> :binary.encode_unsigned()
    |> byte_size()
    |> max(1)
  end

  defp integer_unbiased(max, threshold, byte_count) do
    value = :crypto.strong_rand_bytes(byte_count) |> :binary.decode_unsigned()

    if value < threshold do
      rem(value, max)
    else
      # coveralls-ignore-start
      integer_unbiased(max, threshold, byte_count)
      # coveralls-ignore-stop
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
    case Enum.to_list(enumerable) do
      [] -> nil
      list -> Enum.at(list, integer(length(list)))
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
