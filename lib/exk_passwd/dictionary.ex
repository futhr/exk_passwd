defmodule ExkPasswd.Dictionary do
  @moduledoc """
  Dictionary word list management with compile-time optimizations.

  This module provides constant-time random word selection through tuple-based storage
  and pre-transformed case variants.

  ## Optimizations

  1. **Tuple-based storage**: Words stored as tuples for constant-time indexed access
  2. **Pre-transformed cases**: Separate uppercase/lowercase/capitalized variants
  3. **Pre-computed ranges**: Common word length ranges pre-computed at compile time
  4. **Custom dictionary support**: Runtime `:persistent_term` storage for user dictionaries

  ## Implementation

  - Word selection: Constant-time tuple indexing
  - Case transformation: Pre-computed variants eliminate runtime transformation
  - Memory cost: ~200KB additional for pre-computed variants

  ## Word List Source

  The word list is the **EFF Large Wordlist** (7,772 of its 7,776 words),
  developed by the Electronic Frontier Foundation specifically for passphrase
  generation: https://www.eff.org/deeplinks/2016/07/new-wordlists-random-passphrases

  The four hyphenated entries (`drop-down`, `felt-tip`, `t-shirt`, `yo-yo`)
  are excluded so every word is strictly lowercase `a-z` and cannot collide
  with separator characters. See `docs/SECURITY.md` for checksums and
  provenance.

  This wordlist provides:
  - **High entropy**: 7,772 words = ~12.92 bits per word
  - **Memorable words**: Common, easy-to-remember English words
  - **Typability**: No complex spellings or obscure words
  - **Safety**: No offensive or problematic words

  ## Custom Dictionaries

  You can load custom dictionaries at runtime for specific use cases:

      ExkPasswd.Dictionary.load_custom(:spanish, ["casa", "perro", "gato", ...])
      ExkPasswd.Dictionary.random_word_between(4, 8, :none, :spanish)

  Custom dictionaries are stored in `:persistent_term`, so they survive the
  process that loaded them and reads are zero-copy. Loading (or deleting) a
  dictionary triggers a global GC scan — load dictionaries once at application
  start rather than in hot paths. Use `delete_custom/1` to remove one.

  ## Examples

      iex> ExkPasswd.Dictionary.size()
      7772

      iex> word = ExkPasswd.Dictionary.random_word_between(4, 8)
      ...> len = String.length(word)
      ...> len >= 4 and len <= 8
      true

      iex> word = ExkPasswd.Dictionary.random_word_between(5, 7, :capitalize)
      ...> len = String.length(word)
      ...> len >= 5 and len <= 7
      true
      iex> String.first(word) == String.upcase(String.first(word))
      true
  """

  alias ExkPasswd.{Buffer, Random}

  # Load EFF Large Wordlist from priv directory at compile time
  @external_resource wordlist_path = Path.join([__DIR__, "../../priv/dict/eff_large.txt"])

  @words wordlist_path
         |> File.read!()
         |> String.split("\n", trim: true)
         |> Enum.map(&String.trim/1)
         |> Enum.reject(&(&1 == ""))

  @word_count length(@words)

  # Pre-calculate min and max word lengths
  @min_length @words |> Enum.map(&String.length/1) |> Enum.min()
  @max_length @words |> Enum.map(&String.length/1) |> Enum.max()

  # Pre-transform words in all case variants at compile time
  @words_lowercase @words |> Enum.map(&String.downcase/1)
  @words_uppercase @words |> Enum.map(&String.upcase/1)
  @words_capitalized @words |> Enum.map(&String.capitalize/1)

  # Pre-index words by length for each case variant
  @words_by_length_original @words
                            |> Enum.group_by(&String.length/1)

  @words_by_length_lower @words_lowercase
                         |> Enum.group_by(&String.length/1)

  @words_by_length_upper @words_uppercase
                         |> Enum.group_by(&String.length/1)

  @words_by_length_capital @words_capitalized
                           |> Enum.group_by(&String.length/1)

  # Convert all word lists to tuples for O(1) access
  # Store as {tuple, count} for efficient random selection
  # Using anonymous function to reduce code duplication
  @to_length_tuples fn words_by_length ->
    for {len, words} <- words_by_length, into: %{} do
      {len, {List.to_tuple(words), length(words)}}
    end
  end

  @words_by_length_tuples_original @to_length_tuples.(@words_by_length_original)
  @words_by_length_tuples_lower @to_length_tuples.(@words_by_length_lower)
  @words_by_length_tuples_upper @to_length_tuples.(@words_by_length_upper)
  @words_by_length_tuples_capital @to_length_tuples.(@words_by_length_capital)

  # Pre-compute common word ranges (3-10 min/max combinations) as tuples
  # This provides O(1) access for the most common use cases
  @to_range_tuples fn words_by_length ->
    for min <- 3..10, max <- 3..10, min <= max, into: %{} do
      words =
        min..max
        |> Enum.flat_map(fn len ->
          Map.get(words_by_length, len, [])
        end)

      {{min, max}, {List.to_tuple(words), length(words)}}
    end
  end

  @range_tuples_original @to_range_tuples.(@words_by_length_original)
  @range_tuples_lower @to_range_tuples.(@words_by_length_lower)
  @range_tuples_upper @to_range_tuples.(@words_by_length_upper)
  @range_tuples_capital @to_range_tuples.(@words_by_length_capital)

  @doc """
  No-op kept for backwards compatibility.

  Earlier versions stored custom dictionaries in an ETS table that required
  initialization. Custom dictionaries now live in `:persistent_term`, which
  needs no setup, so calling this function is no longer necessary.
  """
  @deprecated "Custom dictionaries no longer require initialization"
  @spec init() :: :ok
  def init, do: :ok

  @doc """
  Load a custom dictionary for runtime use.

  The dictionary is stored in `:persistent_term` and can be referenced by name
  when generating passwords. Storage is process-independent: the dictionary
  remains available even after the process that loaded it exits.

  Loading a dictionary triggers a global GC scan (a property of
  `:persistent_term` updates), so load dictionaries once at application start
  rather than in hot paths.

  ## Parameters

  - `name` - Atom identifier for the dictionary
  - `wordlist` - Non-empty list of unique, valid UTF-8 words

  ## Examples

      iex> words = ["casa", "perro", "gato", "libro"]
      ...> ExkPasswd.Dictionary.load_custom(:spanish, words)
      :ok

  Words are normalized to Unicode NFC. Empty lists, invalid strings, and words
  that become duplicates after normalization raise `ArgumentError`. Case
  variants that produce the same output are stored once so every reachable
  output remains uniformly selectable.
  """
  @spec load_custom(atom(), [String.t()]) :: :ok
  def load_custom(:eff, _) do
    raise ArgumentError, ":eff is reserved for the built-in dictionary"
  end

  def load_custom(name, wordlist) when is_atom(name) and is_list(wordlist) do
    wordlist = normalize_wordlist!(wordlist)

    {t_orig, r_orig} = build_variant(wordlist, & &1)
    {t_lower, r_lower} = build_variant(wordlist, &String.downcase/1)
    {t_upper, r_upper} = build_variant(wordlist, &String.upcase/1)
    {t_capital, r_capital} = build_variant(wordlist, &String.capitalize/1)

    prepared = %{
      size: length(wordlist),
      by_length: %{
        original: t_orig,
        lower: t_lower,
        upper: t_upper,
        capitalize: t_capital
      },
      ranges: %{
        original: r_orig,
        lower: r_lower,
        upper: r_upper,
        capitalize: r_capital
      }
    }

    :persistent_term.put(persistent_key(name), prepared)
    :ok
  end

  def load_custom(name, wordlist) do
    raise ArgumentError,
          "dictionary name must be an atom and wordlist must be a list, got: " <>
            "#{inspect(name)}, #{inspect(wordlist)}"
  end

  @doc """
  Delete a previously loaded custom dictionary.

  Returns `:ok` whether or not the dictionary existed. Like `load_custom/2`,
  this updates `:persistent_term` and triggers a global GC scan, so prefer
  loading dictionaries once over repeated load/delete cycles.

  ## Examples

      iex> ExkPasswd.Dictionary.load_custom(:temporary, ["uno", "dos", "tres"])
      ...> ExkPasswd.Dictionary.delete_custom(:temporary)
      :ok
  """
  @spec delete_custom(atom()) :: :ok
  def delete_custom(:eff) do
    raise ArgumentError, ":eff is the built-in dictionary and cannot be deleted"
  end

  def delete_custom(name) when is_atom(name) do
    :persistent_term.erase(persistent_key(name))
    :ok
  end

  def delete_custom(name) do
    raise ArgumentError, "dictionary name must be an atom, got: #{inspect(name)}"
  end

  @doc """
  Returns all words in the default dictionary.

  ## Examples

      iex> words = ExkPasswd.Dictionary.all()
      ...> is_list(words)
      true
      iex> length(words) > 0
      true
  """
  @spec all() :: [String.t()]
  def all, do: @words

  @doc """
  Returns the total number of words in the default dictionary.

  ## Examples

      iex> ExkPasswd.Dictionary.size()
      7772
  """
  @spec size() :: pos_integer()
  def size, do: @word_count

  @doc """
  Returns the minimum word length in the default dictionary.

  ## Examples

      iex> ExkPasswd.Dictionary.min_length()
      3
  """
  @spec min_length() :: pos_integer()
  def min_length, do: @min_length

  @doc """
  Returns the maximum word length in the default dictionary.

  ## Examples

      iex> ExkPasswd.Dictionary.max_length()
      9
  """
  @spec max_length() :: pos_integer()
  def max_length, do: @max_length

  @doc """
  Returns the count of words between min and max length (inclusive).

  Supports both default `:eff` dictionary and custom dictionaries.

  Unknown custom dictionaries return `0` rather than raising. Callers such as
  `ExkPasswd.Entropy` treat that as zero word entropy, which degrades
  conservatively (entropy is understated, never overstated).

  ## Parameters

  - `min` - Minimum word length (inclusive)
  - `max` - Maximum word length (inclusive)
  - `dict` - Dictionary to use (`:eff` or custom name, default `:eff`)

  ## Examples

      iex> count = ExkPasswd.Dictionary.count_between(4, 8)
      ...> is_integer(count) and count > 0
      true
  """
  @spec count_between(pos_integer(), pos_integer(), atom()) :: non_neg_integer()
  def count_between(min, max, dict \\ :eff)

  def count_between(min, max, :eff) when min <= max do
    case Map.get(@range_tuples_original, {min, max}) do
      {_, count} -> count
      nil -> count_between_fallback(min, max, @words_by_length_original)
    end
  end

  def count_between(max, min, :eff), do: count_between(min, max, :eff)

  def count_between(min, max, dict_name) when is_atom(dict_name) do
    case fetch_custom(dict_name) do
      nil ->
        # Unknown dictionaries count as empty rather than raising, so entropy
        # calculations degrade conservatively (toward zero word entropy).
        0

      data ->
        case Map.get(data.ranges.original, {min, max}) do
          {_, count} -> count
          nil -> count_between_fallback(min, max, data.by_length.original)
        end
    end
  end

  defp count_between_fallback(min, max, by_length) do
    lower = min(min, max)
    upper = max(min, max)

    Enum.reduce(by_length, 0, fn {length, bucket}, acc ->
      if length >= lower and length <= upper, do: acc + bucket_size(bucket), else: acc
    end)
  end

  @doc """
  Returns the unique dictionary outputs available for a length range and case variant.

  This is primarily useful for auditing a configured output space. Unknown
  custom dictionaries return an empty list.

  ## Parameters

  - `min` - Minimum word length, inclusive
  - `max` - Maximum word length, inclusive
  - `case_transform` - One of `:none`, `:lower`, `:upper`, or `:capitalize`
  - `dict` - `:eff` or the name of a loaded custom dictionary
  """
  @spec words_between(pos_integer(), pos_integer(), atom(), atom()) :: [String.t()]
  def words_between(min, max, case_transform \\ :none, dict \\ :eff)

  def words_between(min, max, case_transform, :eff)
      when case_transform in [:none, :lower, :upper, :capitalize] do
    case get_tuples_map(case_transform) |> tuple_between(min, max) do
      {_, 0} -> []
      {tuple, _} -> Tuple.to_list(tuple)
    end
  end

  def words_between(min, max, case_transform, dict)
      when is_atom(dict) and case_transform in [:none, :lower, :upper, :capitalize] do
    case fetch_custom(dict) do
      nil ->
        []

      data ->
        case_key = case_transform_to_key(case_transform)

        case get_in(data, [:by_length, case_key]) |> tuple_between(min, max) do
          {_, 0} -> []
          {tuple, _} -> Tuple.to_list(tuple)
        end
    end
  end

  def words_between(_, _, case_transform, dict) do
    raise ArgumentError,
          "case transform and dictionary must be supported atoms, got: " <>
            "#{inspect(case_transform)}, #{inspect(dict)}"
  end

  @doc """
  Returns a random word between min and max length with optional case transformation.

  Uses tuple-based constant-time lookups for efficient word selection.

  ## Parameters

  - `min` - Minimum word length (inclusive)
  - `max` - Maximum word length (inclusive)
  - `case_transform` - Case transform to apply (`:none`, `:lower`, `:upper`, `:capitalize`)
  - `dict` - Dictionary to use (`:eff` or custom name)

  ## Returns

  A random word with the specified length and case, or `nil` if none exist.

  ## Examples

      iex> word = ExkPasswd.Dictionary.random_word_between(4, 8)
      ...> len = String.length(word)
      ...> len >= 4 and len <= 8
      true

      iex> word = ExkPasswd.Dictionary.random_word_between(5, 7, :upper)
      ...> word == String.upcase(word)
      true
  """
  @spec random_word_between(pos_integer(), pos_integer(), atom(), atom()) :: String.t() | nil
  def random_word_between(min, max, case_transform \\ :none, dict \\ :eff)

  # Fast path for default dictionary with common ranges (all case variants)
  def random_word_between(min, max, case_transform, :eff)
      when min <= max and case_transform in [:none, :lower, :upper, :capitalize] do
    range_tuples = get_range_tuples(case_transform)

    case Map.get(range_tuples, {min, max}) do
      # Pre-computed bucket exists but holds no words: the range is genuinely empty
      {_, 0} ->
        nil

      {tuple, count} ->
        index = Random.integer(count)
        :erlang.element(index + 1, tuple)

      nil ->
        random_word_between_fallback(min, max, case_transform, :eff)
    end
  end

  # Handle reversed min/max
  def random_word_between(max, min, case_transform, dict) when max > min do
    random_word_between(min, max, case_transform, dict)
  end

  # Custom dictionary support
  def random_word_between(min, max, case_transform, dict_name)
      when is_atom(dict_name) and dict_name != :eff and
             case_transform in [:none, :lower, :upper, :capitalize] do
    case fetch_custom(dict_name) do
      nil ->
        nil

      data ->
        case_key = case_transform_to_key(case_transform)
        ranges = get_in(data, [:ranges, case_key])

        case Map.get(ranges, {min, max}) do
          # Pre-computed bucket exists but holds no words: the range is genuinely empty
          {_, 0} ->
            nil

          {tuple, count} ->
            index = Random.integer(count)
            :erlang.element(index + 1, tuple)

          nil ->
            # Fallback: dynamically build tuple for uncommon ranges
            random_word_between_custom_fallback(min, max, case_key, data)
        end
    end
  end

  def random_word_between(_, _, case_transform, dict) do
    raise ArgumentError,
          "case transform and dictionary must be supported atoms, got: " <>
            "#{inspect(case_transform)}, #{inspect(dict)}"
  end

  # Fallback for uncommon ranges (dynamically build tuple)
  defp random_word_between_fallback(min, max, case_transform, :eff) do
    tuples_map = get_tuples_map(case_transform)

    case tuple_between(tuples_map, min, max) do
      {_, 0} -> nil
      {tuple, count} -> :erlang.element(Random.integer(count) + 1, tuple)
    end
  end

  defp get_tuples_map(:none), do: @words_by_length_tuples_original
  defp get_tuples_map(:lower), do: @words_by_length_tuples_lower
  defp get_tuples_map(:upper), do: @words_by_length_tuples_upper
  defp get_tuples_map(:capitalize), do: @words_by_length_tuples_capital

  defp get_range_tuples(:none), do: @range_tuples_original
  defp get_range_tuples(:lower), do: @range_tuples_lower
  defp get_range_tuples(:upper), do: @range_tuples_upper
  defp get_range_tuples(:capitalize), do: @range_tuples_capital

  defp case_transform_to_key(:none), do: :original
  defp case_transform_to_key(:lower), do: :lower
  defp case_transform_to_key(:upper), do: :upper
  defp case_transform_to_key(:capitalize), do: :capitalize

  # Fallback for custom dictionaries with uncommon ranges
  defp random_word_between_custom_fallback(min, max, case_key, data) do
    by_length = get_in(data, [:by_length, case_key])

    case tuple_between(by_length, min, max) do
      {_, 0} -> nil
      {tuple, count} -> :erlang.element(Random.integer(count) + 1, tuple)
    end
  end

  defp build_variant(wordlist, transform_fn) do
    by_length =
      wordlist
      |> Enum.map(transform_fn)
      |> Enum.uniq()
      |> Enum.group_by(&String.length/1)

    tuples =
      for {len, words} <- by_length, into: %{} do
        {len, {List.to_tuple(words), length(words)}}
      end

    {tuples, build_range_tuples(by_length)}
  end

  # Helper function for building range tuples at runtime (for custom dictionaries)
  # words_by_length is never empty: load_custom/2 validates wordlists up front
  defp build_range_tuples(words_by_length) do
    lengths = Map.keys(words_by_length)
    # Configured word lengths stop at 50. Bounding the cache prevents sparse
    # dictionaries from allocating ranges across extreme gaps; direct queries
    # still use the by-length fallback.
    min_len = lengths |> Enum.min() |> max(1)
    max_len = lengths |> Enum.max() |> min(50)

    if min_len <= max_len do
      for min <- min_len..max_len,
          max <- min..max_len,
          max - min <= 10,
          into: %{} do
        words =
          min..max
          |> Enum.flat_map(&Map.get(words_by_length, &1, []))

        {{min, max}, {List.to_tuple(words), length(words)}}
      end
    else
      %{}
    end
  end

  @doc """
  Select a random word using a stateful Buffer generator.

  This is an optimized version for batch generation that accepts and returns
  a Buffer state, reducing the number of `:crypto.strong_rand_bytes/1`
  syscalls.

  ## Parameters

  - `min` - Minimum word length
  - `max` - Maximum word length
  - `case_transform` - Case transformation to apply
  - `dict` - Dictionary name (default: :eff)
  - `random_state` - A `Buffer.t()` state

  ## Returns

  A tuple of {word, new_random_state}

  ## Examples

      iex> alias ExkPasswd.Buffer
      ...> state = Buffer.new(1_000)
      ...>
      ...> {word, _new_state} =
      ...>   ExkPasswd.Dictionary.random_word_between_with_state(4, 8, :none, :eff, state)
      ...>
      ...> len = String.length(word)
      ...> len >= 4 and len <= 8
      true
  """
  @spec random_word_between_with_state(
          non_neg_integer(),
          non_neg_integer(),
          atom(),
          atom(),
          ExkPasswd.Buffer.t()
        ) :: {String.t() | nil, Buffer.t()}
  def random_word_between_with_state(
        min,
        max,
        case_transform \\ :none,
        dict \\ :eff,
        random_state
      )

  # Fast path for default dictionary with common ranges (all case variants)
  def random_word_between_with_state(min, max, case_transform, :eff, random_state)
      when min <= max and case_transform in [:none, :lower, :upper, :capitalize] do
    range_tuples = get_range_tuples(case_transform)

    case Map.get(range_tuples, {min, max}) do
      # Pre-computed bucket exists but holds no words: the range is genuinely empty
      {_, 0} ->
        {nil, random_state}

      {tuple, count} ->
        {index, new_state} = ExkPasswd.Buffer.random_integer(random_state, count)
        word = :erlang.element(index + 1, tuple)
        {word, new_state}

      nil ->
        random_word_between_with_state_fallback(
          min,
          max,
          get_tuples_map(case_transform),
          random_state
        )
    end
  end

  def random_word_between_with_state(max, min, case_transform, dict, random_state)
      when max > min do
    random_word_between_with_state(min, max, case_transform, dict, random_state)
  end

  def random_word_between_with_state(min, max, case_transform, dict_name, random_state)
      when is_atom(dict_name) and dict_name != :eff and
             case_transform in [:none, :lower, :upper, :capitalize] do
    case fetch_custom(dict_name) do
      nil ->
        raise ArgumentError,
              "Dictionary '#{dict_name}' not found. Load it first with load_custom/2"

      data ->
        case_key = case_transform_to_key(case_transform)
        ranges = get_in(data, [:ranges, case_key])

        case Map.get(ranges, {min, max}) do
          # Pre-computed bucket exists but holds no words: the range is genuinely empty
          {_, 0} ->
            {nil, random_state}

          {tuple, count} ->
            {index, new_state} = ExkPasswd.Buffer.random_integer(random_state, count)
            word = :erlang.element(index + 1, tuple)
            {word, new_state}

          nil ->
            random_word_between_with_state_fallback(
              min,
              max,
              get_in(data, [:by_length, case_key]),
              random_state
            )
        end
    end
  end

  def random_word_between_with_state(
        _,
        _,
        case_transform,
        dict,
        _
      ) do
    raise ArgumentError,
          "case transform and dictionary must be supported atoms, got: " <>
            "#{inspect(case_transform)}, #{inspect(dict)}"
  end

  # Custom dictionaries are keyed per name so loads and deletes of one
  # dictionary never touch the others.
  defp persistent_key(name), do: {__MODULE__, name}

  defp fetch_custom(name), do: :persistent_term.get(persistent_key(name), nil)

  defp normalize_wordlist!(wordlist) do
    if wordlist == [] or
         Enum.any?(wordlist, &(not is_binary(&1) or &1 == "" or not String.valid?(&1))) do
      raise ArgumentError,
            "wordlist must be a non-empty list of non-empty strings containing valid UTF-8"
    end

    normalized = Enum.map(wordlist, &String.normalize(&1, :nfc))

    if length(Enum.uniq(normalized)) != length(normalized) do
      raise ArgumentError, "wordlist contains duplicate words after Unicode normalization"
    end

    normalized
  end

  defp tuple_between(by_length, min, max) do
    lower = min(min, max)
    upper = max(min, max)

    words =
      by_length
      |> Enum.filter(fn {length, _} -> length >= lower and length <= upper end)
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.flat_map(fn {_, {tuple, _}} -> Tuple.to_list(tuple) end)

    {List.to_tuple(words), length(words)}
  end

  defp bucket_size({_, count}), do: count
  defp bucket_size(words) when is_list(words), do: length(words)

  defp random_word_between_with_state_fallback(min, max, by_length, random_state) do
    case tuple_between(by_length, min, max) do
      {_, 0} ->
        {nil, random_state}

      {tuple, count} ->
        {index, new_state} = Buffer.random_integer(random_state, count)
        {:erlang.element(index + 1, tuple), new_state}
    end
  end
end
