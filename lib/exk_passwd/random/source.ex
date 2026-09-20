defmodule ExkPasswd.Random.Source do
  @moduledoc """
  Dispatches requests for cryptographically secure random bytes.

  `ExkPasswd.Random` and `ExkPasswd.Buffer` use this module as their common
  byte-source boundary. The default implementation is
  `ExkPasswd.Random.CryptoSource`, which delegates to
  `:crypto.strong_rand_bytes/1`.

  Source selection happens at compile time. ExkPasswd's security guarantees
  assume that production builds use the default implementation. A replacement
  source becomes part of the application's security boundary and must satisfy
  the contract below.

  ## Security contract

  An implementation of this behaviour must:

  - return exactly the requested number of bytes;
  - obtain every byte from a cryptographically secure random number generator;
  - raise when secure randomness is unavailable instead of returning predictable
    data.

  ## Examples

      iex> bytes = ExkPasswd.Random.Source.strong_bytes(16)
      ...> byte_size(bytes)
      16
  """

  @source Application.compile_env(
            :exk_passwd,
            :random_source,
            ExkPasswd.Random.CryptoSource
          )
  @test_seam Application.compile_env(:exk_passwd, :random_source_test_seam, false)

  @doc """
  Defines the byte operation required of a secure random source.

  `count` is the exact number of bytes the implementation must return. The
  bytes must be independent and cryptographically unpredictable.
  """
  @callback strong_bytes(non_neg_integer()) :: binary()

  @strong_bytes_doc """
  Returns `count` cryptographically secure random bytes.

  ExkPasswd uses these bytes for unbiased integer sampling. This function raises
  if the configured source cannot provide secure randomness.

  ## Parameters

  - `count` - exact number of bytes to return; must be a non-negative integer.

  ## Returns

  A binary containing exactly `count` bytes.

  ## Examples

      iex> bytes = ExkPasswd.Random.Source.strong_bytes(8)
      iex> byte_size(bytes)
      8

      iex> ExkPasswd.Random.Source.strong_bytes(0)
      <<>>
  """

  if @test_seam do
    @test_source_key {__MODULE__, :test_source}
    @doc false
    @spec with_source(module(), (-> result)) :: result when result: term()
    def with_source(source, operation) when is_atom(source) and is_function(operation, 0) do
      previous = Process.get(@test_source_key)
      Process.put(@test_source_key, source)

      try do
        operation.()
      after
        restore_source(previous)
      end
    end

    @doc @strong_bytes_doc
    @spec strong_bytes(non_neg_integer()) :: binary()
    def strong_bytes(count) do
      case Process.get(@test_source_key) do
        nil -> @source.strong_bytes(count)
        source -> source.strong_bytes(count)
      end
    end

    defp restore_source(nil), do: Process.delete(@test_source_key)
    defp restore_source(source), do: Process.put(@test_source_key, source)
  else
    @doc @strong_bytes_doc
    @spec strong_bytes(non_neg_integer()) :: binary()
    def strong_bytes(count), do: @source.strong_bytes(count)
  end
end
