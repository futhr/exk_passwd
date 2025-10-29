defmodule ExkPasswd.Dictionary do
  @moduledoc """
  Dictionary word list management with compile-time optimizations.

  This module provides constant-time random word selection through tuple-based storage
  and pre-transformed case variants.

  ## Optimizations

  1. **Tuple-based storage**: Words stored as tuples for constant-time indexed access
  2. **Pre-transformed cases**: Separate uppercase/lowercase/capitalized variants
  3. **Pre-computed ranges**: Common word length ranges pre-computed at compile time
  4. **Custom dictionary support**: Runtime ETS-based storage for user dictionaries

  ## Implementation

  - Word selection: Constant-time tuple indexing
  - Case transformation: Pre-computed variants eliminate runtime transformation
  - Memory cost: ~200KB additional for pre-computed variants

  ## Word List Source

  The word list uses the **EFF Large Wordlist** (7,826 words), developed by the
  Electronic Frontier Foundation specifically for passphrase generation:
  https://www.eff.org/deeplinks/2016/07/new-wordlists-random-passphrases

  This wordlist provides:
  - **High entropy**: 7,826 words = ~12.93 bits per word
  - **Memorable words**: Common, easy-to-remember English words
  - **Typability**: No complex spellings or obscure words
  - **Safety**: No offensive or problematic words

  ## Custom Dictionaries

  You can load custom dictionaries at runtime for specific use cases:

      ExkPasswd.Dictionary.load_custom(:spanish, ["casa", "perro", "gato", ...])
      ExkPasswd.Dictionary.random_word_between(4, 8, :spanish)

  ## Examples

      iex> ExkPasswd.Dictionary.size()
      7826

      iex> word = ExkPasswd.Dictionary.random_word_between(4, 8)
      iex> len = String.length(word)
      iex> len >= 4 and len <= 8
      true

      iex> word = ExkPasswd.Dictionary.random_word_between(5, 7, :capitalize)
      iex> len = String.length(word)
      iex> len >= 5 and len <= 7
      true
      iex> String.first(word) == String.upcase(String.first(word))
      true
  """

  alias ExkPasswd.Random

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
  @words_by_length_tuples_original (for {len, words} <- @words_by_length_original, into: %{} do
                                      {len, {List.to_tuple(words), length(words)}}
                                    end)

  @words_by_length_tuples_lower (for {len, words} <- @words_by_length_lower, into: %{} do
                                   {len, {List.to_tuple(words), length(words)}}
                                 end)

  @words_by_length_tuples_upper (for {len, words} <- @words_by_length_upper, into: %{} do
                                   {len, {List.to_tuple(words), length(words)}}
                                 end)

  @words_by_length_tuples_capital (for {len, words} <- @words_by_length_capital, into: %{} do
                                     {len, {List.to_tuple(words), length(words)}}
                                   end)

  # Pre-compute common word ranges (4-10 min/max combinations) as tuples
  # This provides O(1) access for the most common use cases
  @range_tuples_original (for min <- 3..10, max <- 3..10, min <= max, into: %{} do
                            words =
                              min..max
                              |> Enum.flat_map(fn len ->
                                Map.get(@words_by_length_original, len, [])
                              end)

                            {{min, max}, {List.to_tuple(words), length(words)}}
                          end)

  @range_tuples_lower (for min <- 3..10, max <- 3..10, min <= max, into: %{} do
                         words =
                           min..max
                           |> Enum.flat_map(fn len ->
                             Map.get(@words_by_length_lower, len, [])
                           end)

                         {{min, max}, {List.to_tuple(words), length(words)}}
                       end)

  @range_tuples_upper (for min <- 3..10, max <- 3..10, min <= max, into: %{} do
                         words =
                           min..max
                           |> Enum.flat_map(fn len ->
                             Map.get(@words_by_length_upper, len, [])
                           end)

                         {{min, max}, {List.to_tuple(words), length(words)}}
                       end)

  @range_tuples_capital (for min <- 3..10, max <- 3..10, min <= max, into: %{} do
                           words =
                             min..max
                             |> Enum.flat_map(fn len ->
                               Map.get(@words_by_length_capital, len, [])
                             end)

                           {{min, max}, {List.to_tuple(words), length(words)}}
                         end)

  # ETS table name for custom dictionaries
  @ets_table :exk_passwd_custom_dicts

  @doc """
  Initialize ETS table for custom dictionaries.

  Called automatically when the application starts.
  """
  def init do
    case :ets.whereis(@ets_table) do
      :undefined ->
        :ets.new(@ets_table, [:set, :public, :named_table, read_concurrency: true])

      _table ->
        :ok
    end
  end

  @doc """
  Load a custom dictionary for runtime use.

  The dictionary will be stored in ETS and can be referenced by name
  when generating passwords.

  ## Parameters

  - `name` - Atom identifier for the dictionary
  - `wordlist` - List of words (strings)

  ## Examples

      iex> words = ["casa", "perro", "gato", "libro"]
      iex> ExkPasswd.Dictionary.load_custom(:spanish, words)
      :ok
  """
  @spec load_custom(atom(), [String.t()]) :: :ok
  def load_custom(name, wordlist) when is_atom(name) and is_list(wordlist) do
    init()

    # Prepare all case variants
    words_original = wordlist
    words_lower = Enum.map(wordlist, &String.downcase/1)
    words_upper = Enum.map(wordlist, &String.upcase/1)
    words_capital = Enum.map(wordlist, &String.capitalize/1)

    # Index by length
    by_length_original = Enum.group_by(words_original, &String.length/1)
    by_length_lower = Enum.group_by(words_lower, &String.length/1)
    by_length_upper = Enum.group_by(words_upper, &String.length/1)
    by_length_capital = Enum.group_by(words_capital, &String.length/1)

    # Convert to tuples
    tuples_original =
      for {len, words} <- by_length_original, into: %{} do
        {len, {List.to_tuple(words), length(words)}}
      end

    tuples_lower =
      for {len, words} <- by_length_lower, into: %{} do
        {len, {List.to_tuple(words), length(words)}}
      end

    tuples_upper =
      for {len, words} <- by_length_upper, into: %{} do
        {len, {List.to_tuple(words), length(words)}}
      end

    tuples_capital =
      for {len, words} <- by_length_capital, into: %{} do
        {len, {List.to_tuple(words), length(words)}}
      end

    # Build range tuples
    range_original = build_range_tuples(by_length_original)
    range_lower = build_range_tuples(by_length_lower)
    range_upper = build_range_tuples(by_length_upper)
    range_capital = build_range_tuples(by_length_capital)

    prepared = %{
      size: length(wordlist),
      by_length: %{
        original: tuples_original,
        lower: tuples_lower,
        upper: tuples_upper,
        capitalize: tuples_capital
      },
      ranges: %{
        original: range_original,
        lower: range_lower,
        upper: range_upper,
        capitalize: range_capital
      }
    }

    :ets.insert(@ets_table, {name, prepared})
    :ok
  end

  @doc """
  Returns all words in the default dictionary.

  ## Examples

      iex> words = ExkPasswd.Dictionary.all()
      iex> is_list(words)
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
      7826
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
      10
  """
  @spec max_length() :: pos_integer()
  def max_length, do: @max_length

  @doc """
  Returns the count of words between min and max length (inclusive).

  Supports both default `:eff` dictionary and custom dictionaries.

  ## Parameters

  - `min` - Minimum word length (inclusive)
  - `max` - Maximum word length (inclusive)
  - `dict` - Dictionary to use (`:eff` or custom name, default `:eff`)

  ## Examples

      iex> count = ExkPasswd.Dictionary.count_between(4, 8)
      iex> is_integer(count) and count > 0
      true
  """
  @spec count_between(pos_integer(), pos_integer(), atom()) :: non_neg_integer()
  def count_between(min, max, dict \\ :eff)

  def count_between(min, max, :eff) when min <= max do
    case Map.get(@range_tuples_original, {min, max}) do
      {_tuple, count} -> count
      nil -> count_between_fallback(min, max, @words_by_length_original)
    end
  end

  def count_between(max, min, :eff), do: count_between(min, max, :eff)

  def count_between(min, max, dict_name) when is_atom(dict_name) do
    case :ets.lookup(@ets_table, dict_name) do
      [{^dict_name, data}] ->
        case Map.get(data.ranges.original, {min, max}) do
          {_tuple, count} -> count
          nil -> count_between_fallback(min, max, data.by_length.original)
        end

      [] ->
        0
    end
  end

  defp count_between_fallback(min, max, by_length) when min <= max do
    min..max
    |> Enum.reduce(0, fn len, acc ->
      case Map.get(by_length, len) do
        {_tuple, count} -> acc + count
        nil -> acc
      end
    end)
  end

  defp count_between_fallback(min, max, by_length) when min > max do
    max..min
    |> Enum.reduce(0, fn len, acc ->
      case Map.get(by_length, len) do
        {_tuple, count} -> acc + count
        nil -> acc
      end
    end)
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
      iex> len = String.length(word)
      iex> len >= 4 and len <= 8
      true

      iex> word = ExkPasswd.Dictionary.random_word_between(5, 7, :upper)
      iex> word == String.upcase(word)
      true
  """
  @spec random_word_between(pos_integer(), pos_integer(), atom(), atom()) :: String.t() | nil
  def random_word_between(min, max, case_transform \\ :none, dict \\ :eff)

  # Fast path for default dictionary with common ranges
  def random_word_between(min, max, :none, :eff) when min <= max do
    case Map.get(@range_tuples_original, {min, max}) do
      {tuple, count} ->
        index = Random.integer(count)
        :erlang.element(index + 1, tuple)

      nil ->
        # Fallback for uncommon ranges
        random_word_between_fallback(min, max, :none, :eff)
    end
  end

  def random_word_between(min, max, :lower, :eff) when min <= max do
    case Map.get(@range_tuples_lower, {min, max}) do
      {tuple, count} ->
        index = Random.integer(count)
        :erlang.element(index + 1, tuple)

      nil ->
        random_word_between_fallback(min, max, :lower, :eff)
    end
  end

  def random_word_between(min, max, :upper, :eff) when min <= max do
    case Map.get(@range_tuples_upper, {min, max}) do
      {tuple, count} ->
        index = Random.integer(count)
        :erlang.element(index + 1, tuple)

      nil ->
        random_word_between_fallback(min, max, :upper, :eff)
    end
  end

  def random_word_between(min, max, :capitalize, :eff) when min <= max do
    case Map.get(@range_tuples_capital, {min, max}) do
      {tuple, count} ->
        index = Random.integer(count)
        :erlang.element(index + 1, tuple)

      nil ->
        random_word_between_fallback(min, max, :capitalize, :eff)
    end
  end

  # Handle reversed min/max
  def random_word_between(max, min, case_transform, dict) when max > min do
    random_word_between(min, max, case_transform, dict)
  end

  # Custom dictionary support
  def random_word_between(min, max, case_transform, dict_name)
      when is_atom(dict_name) and dict_name != :eff do
    case :ets.lookup(@ets_table, dict_name) do
      [{^dict_name, data}] ->
        case_key = case_transform_to_key(case_transform)
        ranges = get_in(data, [:ranges, case_key])

        case Map.get(ranges, {min, max}) do
          {tuple, count} ->
            index = Random.integer(count)
            :erlang.element(index + 1, tuple)

          nil ->
            # Fallback: dynamically build tuple for uncommon ranges
            random_word_between_custom_fallback(min, max, case_key, data)
        end

      [] ->
        nil
    end
  end

  # Fallback for uncommon ranges (dynamically build tuple)
  defp random_word_between_fallback(min, max, case_transform, :eff) do
    tuples_map = get_tuples_map(case_transform)

    words =
      min..max
      |> Enum.flat_map(fn len ->
        case Map.get(tuples_map, len) do
          {tuple, _count} -> Tuple.to_list(tuple)
          nil -> []
        end
      end)

    case words do
      [] -> nil
      _ -> Random.select(words)
    end
  end

  defp get_tuples_map(:none), do: @words_by_length_tuples_original
  defp get_tuples_map(:lower), do: @words_by_length_tuples_lower
  defp get_tuples_map(:upper), do: @words_by_length_tuples_upper
  defp get_tuples_map(:capitalize), do: @words_by_length_tuples_capital

  defp case_transform_to_key(:none), do: :original
  defp case_transform_to_key(:lower), do: :lower
  defp case_transform_to_key(:upper), do: :upper
  defp case_transform_to_key(:capitalize), do: :capitalize

  # Fallback for custom dictionaries with uncommon ranges
  defp random_word_between_custom_fallback(min, max, case_key, data) do
    by_length = get_in(data, [:by_length, case_key])

    words =
      min..max
      |> Enum.flat_map(fn len ->
        case Map.get(by_length, len) do
          {tuple, _count} -> Tuple.to_list(tuple)
          nil -> []
        end
      end)

    case words do
      [] -> nil
      _ -> Random.select(words)
    end
  end

  # Helper function for building range tuples at runtime (for custom dictionaries)
  defp build_range_tuples(words_by_length) do
    # Determine actual min/max lengths in the dictionary
    lengths = Map.keys(words_by_length)

    if Enum.empty?(lengths) do
      %{}
    else
      min_len = Enum.min(lengths)
      max_len = Enum.max(lengths)

      # Precompute common ranges within the actual word lengths
      # Limit to reasonable range size to avoid memory explosion
      for min <- min_len..max_len,
          max <- min..max_len,
          max - min <= 10,
          into: %{} do
        words =
          min..max
          |> Enum.flat_map(fn len ->
            case Map.get(words_by_length, len) do
              # Handle {tuple, count} format (from indexed words)
              {tuple, _count} when is_tuple(tuple) -> Tuple.to_list(tuple)
              # Handle plain list format (from fresh word lists)
              list when is_list(list) -> list
              nil -> []
            end
          end)

        {{min, max}, {List.to_tuple(words), length(words)}}
      end
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
      iex> state = Buffer.new(1_000)
      iex> {word, _new_state} = ExkPasswd.Dictionary.random_word_between_with_state(4, 8, :none, :eff, state)
      iex> len = String.length(word)
      iex> len >= 4 and len <= 8
      true
  """
  @spec random_word_between_with_state(
          non_neg_integer(),
          non_neg_integer(),
          atom(),
          atom(),
          ExkPasswd.Buffer.t()
        ) :: {String.t(), ExkPasswd.Buffer.t()}
  def random_word_between_with_state(
        min,
        max,
        case_transform \\ :none,
        dict \\ :eff,
        random_state
      )

  def random_word_between_with_state(min, max, :none, :eff, random_state) when min <= max do
    case Map.get(@range_tuples_original, {min, max}) do
      {tuple, count} ->
        {index, new_state} = ExkPasswd.Buffer.random_integer(random_state, count)
        word = :erlang.element(index + 1, tuple)
        {word, new_state}

      nil ->
        # Fallback: Use regular method (less optimal but still works)
        word = random_word_between_fallback(min, max, :none, :eff)
        {word, random_state}
    end
  end

  def random_word_between_with_state(min, max, :lower, :eff, random_state) when min <= max do
    case Map.get(@range_tuples_lower, {min, max}) do
      {tuple, count} ->
        {index, new_state} = ExkPasswd.Buffer.random_integer(random_state, count)
        word = :erlang.element(index + 1, tuple)
        {word, new_state}

      nil ->
        word = random_word_between_fallback(min, max, :lower, :eff)
        {word, random_state}
    end
  end

  def random_word_between_with_state(min, max, :upper, :eff, random_state) when min <= max do
    case Map.get(@range_tuples_upper, {min, max}) do
      {tuple, count} ->
        {index, new_state} = ExkPasswd.Buffer.random_integer(random_state, count)
        word = :erlang.element(index + 1, tuple)
        {word, new_state}

      nil ->
        word = random_word_between_fallback(min, max, :upper, :eff)
        {word, random_state}
    end
  end

  def random_word_between_with_state(min, max, :capitalize, :eff, random_state) when min <= max do
    case Map.get(@range_tuples_capital, {min, max}) do
      {tuple, count} ->
        {index, new_state} = ExkPasswd.Buffer.random_integer(random_state, count)
        word = :erlang.element(index + 1, tuple)
        {word, new_state}

      nil ->
        word = random_word_between_fallback(min, max, :capitalize, :eff)
        {word, random_state}
    end
  end

  def random_word_between_with_state(max, min, case_transform, dict, random_state)
      when max > min do
    random_word_between_with_state(min, max, case_transform, dict, random_state)
  end

  def random_word_between_with_state(min, max, case_transform, dict_name, random_state)
      when is_atom(dict_name) and dict_name != :eff do
    case :ets.lookup(@ets_table, dict_name) do
      [{^dict_name, data}] ->
        case_key = case_transform_to_key(case_transform)
        ranges = get_in(data, [:ranges, case_key])

        case Map.get(ranges, {min, max}) do
          {tuple, count} ->
            {index, new_state} = ExkPasswd.Buffer.random_integer(random_state, count)
            word = :erlang.element(index + 1, tuple)
            {word, new_state}

          nil ->
            word = random_word_between_fallback(min, max, case_transform, dict_name)
            {word, random_state}
        end

      [] ->
        raise ArgumentError,
              "Dictionary '#{dict_name}' not found. Load it first with load_custom/2"
    end
  end
end
