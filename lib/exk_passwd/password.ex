defmodule ExkPasswd.Password do
  @moduledoc """
  Password generation with optimized performance.

  This module orchestrates the password generation process using:
  1. Constant-time word selection from tuple-based dictionary
  2. Pre-transformed case variants (eliminates runtime transformation)
  3. Character substitutions (leetspeak) for increased complexity
  4. Configurable dictionary support (default EFF or custom)

  All random operations use cryptographically secure random number generation.

  ## Implementation

  - **Word selection**: Tuple-based constant-time access
  - **Case transformation**: Pre-computed variants eliminate runtime processing
  - **Efficient generation**: Optimized dictionary lookups and transformations

  ## Security

  This module uses `ExkPasswd.Random`, `ExkPasswd.Dictionary`, and `ExkPasswd.Token`
  which all rely on `:crypto.strong_rand_bytes/1` for cryptographic security.

  ## Examples

      iex> password = ExkPasswd.Password.create()
      iex> is_binary(password) and String.length(password) > 0
      true

      iex> config = ExkPasswd.Config.new!(num_words: 2, separator: "-")
      iex> password = ExkPasswd.Password.create(config)
      iex> String.contains?(password, "-")
      true
  """

  alias ExkPasswd.{Buffer, Config, Dictionary, Random, Token, Transform}

  @doc """
  Create a password based on the config either passed in or the default config.

  Uses cryptographically secure random generation for all randomness and
  tuple-based constant-time word selection for efficient generation.

  ## Parameters

  - `config` - A `ExkPasswd.Config` struct. Defaults to the default preset.

  ## Returns

  A randomly generated password string.

  ## Examples

      iex> password = ExkPasswd.Password.create()
      iex> is_binary(password) and String.length(password) > 0
      true

      iex> config = ExkPasswd.Config.new!(num_words: 2, separator: "-")
      iex> password = ExkPasswd.Password.create(config)
      iex> String.contains?(password, "-")
      true
  """
  @spec create(Config.t()) :: String.t()
  def create(config \\ Config.new!()) do
    separator = Token.get_token(config.separator)

    # Select words with optimized O(1) lookup and pre-transformed cases
    words = select_words_optimized(config)

    # Apply custom transforms if configured (extensibility via Transform protocol)
    words = apply_custom_transforms(words, config)

    words
    |> Enum.join(separator)
    |> add_digits(config, separator)
    |> add_padding(config)
  end

  @doc """
  Create a password using a stateful Buffer generator.

  This is an optimized version for batch generation that accepts and returns
  a Buffer state, reducing the number of `:crypto.strong_rand_bytes/1`
  syscalls.

  ## Parameters

  - `config` - A `ExkPasswd.Config` struct
  - `random_state` - A `Buffer.t()` state

  ## Returns

  A tuple of {password, new_random_state}

  ## Examples

      iex> state = ExkPasswd.Buffer.new(1000)
      iex> {password, _new_state} = ExkPasswd.Password.create_with_state(ExkPasswd.Config.new!(), state)
      iex> is_binary(password) and String.length(password) > 0
      true
  """
  @spec create_with_state(Config.t(), Buffer.t()) :: {String.t(), Buffer.t()}
  def create_with_state(config, random_state) do
    separator = Token.get_token(config.separator)

    # Select words using the buffered random state
    {words, random_state} = select_words_with_state(config, random_state)

    # Apply custom transforms
    words = apply_custom_transforms(words, config)

    # Generate digits using the buffered random state
    {digits_before, digits_after} = config.digits

    {digits_before_str, random_state} =
      Token.get_number_with_state(digits_before, random_state)

    {digits_after_str, random_state} =
      Token.get_number_with_state(digits_after, random_state)

    # Join words and add digits
    word_string = Enum.join(words, separator)

    password =
      join(digits_before_str, word_string, separator)
      |> join(digits_after_str, separator)
      |> add_padding(config)

    {password, random_state}
  end

  # Stateful word selection using Buffer
  defp select_words_with_state(config, random_state) do
    select_words_with_state_by_case(
      config.case_transform,
      config,
      random_state,
      config.num_words,
      []
    )
  end

  defp select_words_with_state_by_case(_case_transform, _config, random_state, 0, acc) do
    {Enum.reverse(acc), random_state}
  end

  defp select_words_with_state_by_case(:alternate, config, random_state, remaining, acc) do
    index = config.num_words - remaining
    case_variant = if rem(index, 2) == 0, do: :lower, else: :upper

    {word, random_state} =
      Dictionary.random_word_between_with_state(
        config.word_length.first,
        config.word_length.last,
        case_variant,
        config.dictionary,
        random_state
      )

    select_words_with_state_by_case(:alternate, config, random_state, remaining - 1, [
      word | acc
    ])
  end

  defp select_words_with_state_by_case(:random, config, random_state, remaining, acc) do
    {is_upper, random_state} = Buffer.random_boolean(random_state)
    case_variant = if is_upper, do: :upper, else: :lower

    {word, random_state} =
      Dictionary.random_word_between_with_state(
        config.word_length.first,
        config.word_length.last,
        case_variant,
        config.dictionary,
        random_state
      )

    select_words_with_state_by_case(:random, config, random_state, remaining - 1, [word | acc])
  end

  defp select_words_with_state_by_case(:capitalize, config, random_state, remaining, acc) do
    {word, random_state} =
      Dictionary.random_word_between_with_state(
        config.word_length.first,
        config.word_length.last,
        :capitalize,
        config.dictionary,
        random_state
      )

    select_words_with_state_by_case(:capitalize, config, random_state, remaining - 1, [
      word | acc
    ])
  end

  defp select_words_with_state_by_case(:upper, config, random_state, remaining, acc) do
    {word, random_state} =
      Dictionary.random_word_between_with_state(
        config.word_length.first,
        config.word_length.last,
        :upper,
        config.dictionary,
        random_state
      )

    select_words_with_state_by_case(:upper, config, random_state, remaining - 1, [word | acc])
  end

  defp select_words_with_state_by_case(:lower, config, random_state, remaining, acc) do
    {word, random_state} =
      Dictionary.random_word_between_with_state(
        config.word_length.first,
        config.word_length.last,
        :lower,
        config.dictionary,
        random_state
      )

    select_words_with_state_by_case(:lower, config, random_state, remaining - 1, [word | acc])
  end

  defp select_words_with_state_by_case(:invert, config, random_state, remaining, acc) do
    {word, random_state} =
      Dictionary.random_word_between_with_state(
        config.word_length.first,
        config.word_length.last,
        :none,
        config.dictionary,
        random_state
      )

    inverted_word =
      case String.next_codepoint(word) do
        {head, rest} -> String.downcase(head) <> String.upcase(rest)
        nil -> word
      end

    select_words_with_state_by_case(:invert, config, random_state, remaining - 1, [
      inverted_word | acc
    ])
  end

  defp select_words_with_state_by_case(:none, config, random_state, remaining, acc) do
    {word, random_state} =
      Dictionary.random_word_between_with_state(
        config.word_length.first,
        config.word_length.last,
        :none,
        config.dictionary,
        random_state
      )

    select_words_with_state_by_case(:none, config, random_state, remaining - 1, [word | acc])
  end

  # Optimized word selection using pre-transformed dictionaries
  # This eliminates the need for runtime case transformation
  defp select_words_optimized(%Config{case_transform: :alternate} = config) do
    # Alternate between lower and upper case words
    for i <- 0..(config.num_words - 1) do
      case_variant = if rem(i, 2) == 0, do: :lower, else: :upper

      Dictionary.random_word_between(
        config.word_length.first,
        config.word_length.last,
        case_variant,
        config.dictionary
      )
    end
  end

  defp select_words_optimized(%Config{case_transform: :random} = config) do
    # Each word randomly upper or lower
    for _ <- 1..config.num_words do
      case_variant = if Random.boolean(), do: :upper, else: :lower

      Dictionary.random_word_between(
        config.word_length.first,
        config.word_length.last,
        case_variant,
        config.dictionary
      )
    end
  end

  defp select_words_optimized(%Config{case_transform: :capitalize} = config) do
    # All words capitalized - select from pre-capitalized dictionary
    for _ <- 1..config.num_words do
      Dictionary.random_word_between(
        config.word_length.first,
        config.word_length.last,
        :capitalize,
        config.dictionary
      )
    end
  end

  defp select_words_optimized(%Config{case_transform: :upper} = config) do
    # All words uppercase - select from pre-uppercase dictionary
    for _ <- 1..config.num_words do
      Dictionary.random_word_between(
        config.word_length.first,
        config.word_length.last,
        :upper,
        config.dictionary
      )
    end
  end

  defp select_words_optimized(%Config{case_transform: :lower} = config) do
    # All words lowercase - select from pre-lowercase dictionary
    for _ <- 1..config.num_words do
      Dictionary.random_word_between(
        config.word_length.first,
        config.word_length.last,
        :lower,
        config.dictionary
      )
    end
  end

  defp select_words_optimized(%Config{case_transform: :invert} = config) do
    # Invert case: first letter lowercase, rest uppercase
    # Select lowercase words then transform
    for _ <- 1..config.num_words do
      word =
        Dictionary.random_word_between(
          config.word_length.first,
          config.word_length.last,
          :none,
          config.dictionary
        )

      case String.next_codepoint(word) do
        {head, rest} -> String.downcase(head) <> String.upcase(rest)
        nil -> word
      end
    end
  end

  defp select_words_optimized(%Config{case_transform: :none} = config) do
    # No case transformation - select from original dictionary
    for _ <- 1..config.num_words do
      Dictionary.random_word_between(
        config.word_length.first,
        config.word_length.last,
        :none,
        config.dictionary
      )
    end
  end

  defp add_digits(password, config, separator) do
    {digits_before, digits_after} = config.digits

    join(Token.get_number(digits_before), password, separator)
    |> join(Token.get_number(digits_after), separator)
  end

  # Handle the case when `pad_to_length` is > 0
  defp add_padding(password, config)
       when is_integer(config.padding.to_length) and config.padding.to_length > 0 do
    cond do
      config.padding.to_length < String.length(password) ->
        String.slice(password, 0, config.padding.to_length)

      config.padding.to_length > String.length(password) ->
        password <>
          Token.get_n_of(
            config.padding.char,
            config.padding.to_length - String.length(password)
          )

      true ->
        password
    end
  end

  defp add_padding(password, config) do
    padding_character = Token.get_token(config.padding.char)

    append(Token.get_n_of(padding_character, config.padding.before), password)
    |> append(Token.get_n_of(padding_character, config.padding.after))
  end

  # Apply custom transforms using the Transform protocol
  defp apply_custom_transforms(words, config) do
    transforms = Config.get_meta(config, :transforms, [])

    if Enum.empty?(transforms) do
      words
    else
      Enum.map(words, fn word ->
        Enum.reduce(transforms, word, fn transform, acc ->
          Transform.apply(transform, acc, config)
        end)
      end)
    end
  end

  # Only join words with separator when prefix or suffix is not an empty string.
  defp join("", suffix, _separator), do: suffix
  defp join(prefix, "", _separator), do: prefix

  defp join(prefix, suffix, separator) do
    prefix <> separator <> suffix
  end

  # Only join two values when prefix or suffix is not an empty string.
  defp append("", suffix), do: suffix
  defp append(prefix, ""), do: prefix
  defp append(prefix, suffix), do: prefix <> suffix
end
