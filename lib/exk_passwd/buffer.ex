defmodule ExkPasswd.Buffer do
  @moduledoc """
  Stateful buffered random number generator for batch operations.

  This module provides a more efficient way to generate random numbers when
  performing many operations by pre-allocating a buffer of cryptographically
  secure random bytes and consuming them as needed.

  ## Performance

  By reducing the number of `:crypto.strong_rand_bytes/1` syscalls, this
  can provide 2-3x speedup for batch password generation.

  ## Security

  All random bytes come from `:crypto.strong_rand_bytes/1`, maintaining
  cryptographic security. The buffer is simply a performance optimization
  to batch syscalls.

  ## Examples

      iex> state = ExkPasswd.Buffer.new(1000)
      ...> {value, new_state} = ExkPasswd.Buffer.random_integer(state, 100)
      ...> is_integer(value)
      true
      iex> is_struct(new_state, ExkPasswd.Buffer)
      true

      iex> state = ExkPasswd.Buffer.new(1000)
      ...> {index, new_state} = ExkPasswd.Buffer.random_index(state, 10)
      ...> is_integer(index)
      true
      iex> is_struct(new_state, ExkPasswd.Buffer)
      true
  """

  # 10KB buffer reduces crypto syscalls by ~100x for typical batch sizes
  @default_buffer_size 10_000
  # 4 bytes = 32-bit unsigned integer, provides sufficient entropy for common use cases
  @bytes_per_int 4

  @type t :: %__MODULE__{
          buffer: binary(),
          offset: non_neg_integer(),
          buffer_size: pos_integer()
        }

  defstruct [:buffer, :offset, :buffer_size]

  @doc """
  Create a new buffered random generator.

  ## Parameters

  - `buffer_size` - Size of random byte buffer in bytes (default: 10,000)

  ## Returns

  A new Buffer state struct

  ## Examples

      iex> state = ExkPasswd.Buffer.new()
      ...> is_struct(state, ExkPasswd.Buffer)
      true

      iex> state = ExkPasswd.Buffer.new(5000)
      ...> state.buffer_size
      5000
  """
  @spec new(pos_integer()) :: t()
  def new(buffer_size \\ @default_buffer_size) when buffer_size > 0 do
    %__MODULE__{
      buffer: :crypto.strong_rand_bytes(buffer_size),
      offset: 0,
      buffer_size: buffer_size
    }
  end

  @doc """
  Generate a random integer in the range [0, max).

  Returns a tuple of {random_integer, new_state}.

  ## Parameters

  - `state` - Current Buffer state
  - `max` - Upper bound (exclusive)

  ## Returns

  Tuple of {random_integer, new_state}

  ## Examples

      iex> state = ExkPasswd.Buffer.new()
      ...> {value, new_state} = ExkPasswd.Buffer.random_integer(state, 100)
      ...> is_integer(value)
      true
      iex> is_struct(new_state, ExkPasswd.Buffer)
      true
  """
  @spec random_integer(t(), pos_integer()) :: {non_neg_integer(), t()}
  def random_integer(_state, max) when is_integer(max) and max <= 0 do
    raise ArgumentError, "max must be a positive integer, got: #{max}"
  end

  def random_integer(state, max) when is_integer(max) and max > 0 do
    {bytes, new_state} = consume_bytes(state, @bytes_per_int)

    value =
      bytes
      |> :binary.decode_unsigned()
      |> rem(max)

    {value, new_state}
  end

  @doc """
  Generate a random index for selecting from a list.

  Equivalent to `random_integer/2` but with clearer semantics for list indexing.

  ## Parameters

  - `state` - Current Buffer state
  - `count` - Number of items in the list

  ## Returns

  Tuple of {index, new_state} where index is in range [0, count)

  ## Examples

      iex> state = ExkPasswd.Buffer.new()
      ...> {index, new_state} = ExkPasswd.Buffer.random_index(state, 10)
      ...> is_integer(index)
      true
      iex> is_struct(new_state, ExkPasswd.Buffer)
      true
  """
  @spec random_index(t(), pos_integer()) :: {non_neg_integer(), t()}
  def random_index(state, count) when count > 0 do
    random_integer(state, count)
  end

  @doc """
  Generate a random boolean value.

  Returns a tuple of {boolean, new_state}.

  ## Parameters

  - `state` - Current Buffer state

  ## Returns

  Tuple of {boolean, new_state}

  ## Examples

      iex> state = ExkPasswd.Buffer.new()
      ...> {value, _new_state} = ExkPasswd.Buffer.random_boolean(state)
      ...> is_boolean(value)
      true
  """
  @spec random_boolean(t()) :: {boolean(), t()}
  def random_boolean(state) do
    {bytes, new_state} = consume_bytes(state, 1)

    value =
      bytes
      |> :binary.decode_unsigned()
      |> rem(2)
      |> case do
        0 -> false
        1 -> true
      end

    {value, new_state}
  end

  @doc """
  Generate a random digit (0-9).

  Returns a tuple of {digit, new_state}.

  ## Parameters

  - `state` - Current Buffer state

  ## Returns

  Tuple of {digit, new_state} where digit is in range [0, 9]

  ## Examples

      iex> state = ExkPasswd.Buffer.new()
      ...> {digit, new_state} = ExkPasswd.Buffer.random_digit(state)
      ...> is_integer(digit)
      true
      iex> is_struct(new_state, ExkPasswd.Buffer)
      true
  """
  @spec random_digit(t()) :: {non_neg_integer(), t()}
  def random_digit(state) do
    random_integer(state, 10)
  end

  @doc """
  Select a random element from a list.

  Returns a tuple of {element, new_state}.

  ## Parameters

  - `state` - Current Buffer state
  - `list` - Non-empty list to select from

  ## Returns

  Tuple of {element, new_state}

  ## Examples

      iex> state = ExkPasswd.Buffer.new()
      ...> {elem, _new_state} = ExkPasswd.Buffer.random_element(state, [1, 2, 3])
      ...> elem in [1, 2, 3]
      true
  """
  @spec random_element(t(), nonempty_list(term())) :: {term(), t()}
  def random_element(state, [_ | _] = list) do
    count = length(list)
    {index, new_state} = random_index(state, count)
    {Enum.at(list, index), new_state}
  end

  @spec consume_bytes(t(), pos_integer()) :: {binary(), t()}
  defp consume_bytes(%__MODULE__{buffer: buffer, offset: offset} = state, num_bytes) do
    # Check if we need to refresh the buffer
    if offset + num_bytes > byte_size(buffer) do
      # Generate new buffer
      new_buffer = :crypto.strong_rand_bytes(state.buffer_size)
      bytes = binary_part(new_buffer, 0, num_bytes)
      new_state = %{state | buffer: new_buffer, offset: num_bytes}
      {bytes, new_state}
    else
      # Consume from existing buffer
      bytes = binary_part(buffer, offset, num_bytes)
      new_state = %{state | buffer: buffer, offset: offset + num_bytes}
      {bytes, new_state}
    end
  end
end
