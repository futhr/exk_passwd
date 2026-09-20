defmodule ExkPasswd.Random.CryptoSource do
  @moduledoc """
  Default cryptographically secure byte source for ExkPasswd.

  This module implements `ExkPasswd.Random.Source` by delegating directly to
  `:crypto.strong_rand_bytes/1`. Erlang/OTP obtains those bytes from the host's
  cryptographically secure random number generator.

  No weaker fallback exists. If the runtime cannot provide secure randomness,
  the underlying `:crypto` call raises and password generation fails.

  Most applications should use `ExkPasswd.Random` rather than calling this
  low-level source directly.

  ## Examples

      iex> bytes = ExkPasswd.Random.CryptoSource.strong_bytes(16)
      ...> byte_size(bytes)
      16
  """

  @behaviour ExkPasswd.Random.Source

  @doc """
  Returns `count` bytes from Erlang/OTP's cryptographic random source.

  ## Parameters

  - `count` - exact number of bytes to return; must be a non-negative integer.

  ## Returns

  A binary containing exactly `count` cryptographically secure random bytes.

  ## Examples

      iex> byte_size(ExkPasswd.Random.CryptoSource.strong_bytes(32))
      32

      iex> ExkPasswd.Random.CryptoSource.strong_bytes(0)
      <<>>
  """
  @spec strong_bytes(non_neg_integer()) :: binary()
  @impl ExkPasswd.Random.Source
  def strong_bytes(count), do: :crypto.strong_rand_bytes(count)
end
