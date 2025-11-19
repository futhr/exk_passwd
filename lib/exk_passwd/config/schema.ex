defmodule ExkPasswd.Config.Schema do
  @moduledoc """
  Schema validation for Config structs.

  This module provides declarative schema-based validation with clear error messages.
  """

  alias ExkPasswd.Config

  # Validation bounds constants
  @min_num_words 1
  @max_num_words 10
  @min_digit_count 0
  @max_digit_count 5
  @min_padding 0
  @max_padding 5

  @allowed_symbols ~w(- _ ~ + * = @ ! # & $ % ? . , : ; ^ | / ' " ) ++ [" "]

  @doc """
  Validate a Config struct against the schema.

  ## Parameters

  - `config` - A `%Config{}` struct to validate

  ## Returns

  - `:ok` if valid
  - `{:error, message}` if invalid with a descriptive error message
  """
  @spec validate(Config.t()) :: :ok | {:error, String.t()}
  def validate(%Config{} = config) do
    with :ok <- validate_num_words(config),
         :ok <- validate_word_length(config),
         :ok <- validate_case_transform(config),
         :ok <- validate_separator(config),
         :ok <- validate_digits(config),
         :ok <- validate_padding(config),
         :ok <- validate_substitutions(config),
         :ok <- validate_substitution_mode(config),
         :ok <- validate_dictionary(config) do
      :ok
    end
  end

  # Validate num_words field
  defp validate_num_words(%{num_words: n})
       when is_integer(n) and n >= @min_num_words and n <= @max_num_words do
    :ok
  end

  defp validate_num_words(%{num_words: n}) do
    {:error,
     "num_words must be between #{@min_num_words} and #{@max_num_words}, got: #{inspect(n)}"}
  end

  # Validate word_length field (should be a Range)
  defp validate_word_length(%{word_length: %Range{first: min, last: max}} = config)
       when is_integer(min) and is_integer(max) do
    cond do
      min > max ->
        {:error, "word_length range invalid: #{min}..#{max} (min must be <= max)"}

      min < 1 ->
        {:error, "word_length minimum must be at least 1, got: #{min}"}

      max > 50 ->
        {:error, "word_length maximum must be at most 50, got: #{max}"}

      config.word_length_bounds != nil ->
        validate_word_length_against_bounds(min, max, config.word_length_bounds)

      true ->
        validate_word_length_default_bounds(min, max)
    end
  end

  defp validate_word_length(%{word_length: other}) do
    {:error, "word_length must be a Range (e.g., 4..8), got: #{inspect(other)}"}
  end

  # Validate against default bounds (4-10 for English/Latin scripts)
  defp validate_word_length_default_bounds(min, max)
       when min >= 4 and max <= 10 do
    :ok
  end

  defp validate_word_length_default_bounds(min, max) do
    {:error,
     "word_length range must be between 4 and 10 (English default), got: #{min}..#{max}. " <>
       "For non-Latin scripts, set word_length_bounds (e.g., word_length_bounds: 1..4 for Chinese/Japanese)."}
  end

  # Validate against custom bounds
  defp validate_word_length_against_bounds(min, max, %Range{first: bound_min, last: bound_max})
       when min >= bound_min and max <= bound_max do
    :ok
  end

  defp validate_word_length_against_bounds(min, max, %Range{first: bound_min, last: bound_max}) do
    {:error, "word_length range #{min}..#{max} exceeds custom bounds #{bound_min}..#{bound_max}"}
  end

  # Validate case_transform field
  defp validate_case_transform(%{case_transform: transform})
       when transform in [:none, :alternate, :capitalize, :invert, :lower, :upper, :random] do
    :ok
  end

  defp validate_case_transform(%{case_transform: transform}) do
    {:error,
     "case_transform must be one of :none, :alternate, :capitalize, :invert, :lower, :upper, :random, got: #{inspect(transform)}"}
  end

  # Validate separator field
  defp validate_separator(%{separator: sep}) when is_binary(sep) do
    validate_allowed_symbols(sep, :separator)
  end

  defp validate_separator(%{separator: sep}) do
    {:error, "separator must be a string, got: #{inspect(sep)}"}
  end

  # Validate digits field (should be a tuple {before, after})
  defp validate_digits(%{digits: {before, after_d}})
       when is_integer(before) and is_integer(after_d) and
              before >= @min_digit_count and before <= @max_digit_count and
              after_d >= @min_digit_count and after_d <= @max_digit_count do
    :ok
  end

  defp validate_digits(%{digits: {before, after_d}})
       when is_integer(before) and is_integer(after_d) do
    {:error,
     "digits tuple values must be between #{@min_digit_count} and #{@max_digit_count}, got: {#{before}, #{after_d}}"}
  end

  defp validate_digits(%{digits: other}) do
    {:error, "digits must be a tuple {before, after}, got: #{inspect(other)}"}
  end

  # Validate padding field (should be a map with specific keys)
  defp validate_padding(%{padding: padding}) when is_map(padding) do
    with :ok <- validate_padding_char(padding),
         :ok <- validate_padding_amounts(padding),
         :ok <- validate_padding_to_length(padding) do
      :ok
    end
  end

  defp validate_padding(%{padding: other}) do
    {:error, "padding must be a map, got: #{inspect(other)}"}
  end

  defp validate_padding_char(%{char: char}) when is_binary(char) do
    validate_allowed_symbols(char, :padding_char)
  end

  defp validate_padding_char(%{char: char}) do
    {:error, "padding.char must be a string, got: #{inspect(char)}"}
  end

  defp validate_padding_char(_), do: {:error, "padding map must have a :char key"}

  defp validate_padding_amounts(%{before: before, after: after_p})
       when is_integer(before) and is_integer(after_p) and
              before >= @min_padding and before <= @max_padding and
              after_p >= @min_padding and after_p <= @max_padding do
    :ok
  end

  defp validate_padding_amounts(%{before: before, after: after_p})
       when is_integer(before) and is_integer(after_p) do
    {:error,
     "padding.before and padding.after must be between #{@min_padding} and #{@max_padding}, got: before=#{before}, after=#{after_p}"}
  end

  defp validate_padding_amounts(_) do
    {:error, "padding map must have :before and :after keys with integer values"}
  end

  defp validate_padding_to_length(%{to_length: 0}), do: :ok

  defp validate_padding_to_length(%{to_length: len})
       when is_integer(len) and len >= 8 and len <= 999 do
    :ok
  end

  defp validate_padding_to_length(%{to_length: len}) when is_integer(len) do
    {:error, "padding.to_length must be 0 or between 8 and 999, got: #{len}"}
  end

  defp validate_padding_to_length(_) do
    {:error, "padding map must have a :to_length key with integer value"}
  end

  # Validate substitutions field
  defp validate_substitutions(%{substitutions: subs}) when is_map(subs) do
    # Check all keys and values are strings
    all_strings? =
      Enum.all?(subs, fn {k, v} ->
        is_binary(k) and is_binary(v) and String.length(k) == 1 and String.length(v) == 1
      end)

    if all_strings? do
      :ok
    else
      {:error,
       "substitutions must be a map of single-character strings to single-character strings"}
    end
  end

  defp validate_substitutions(%{substitutions: other}) do
    {:error, "substitutions must be a map, got: #{inspect(other)}"}
  end

  # Validate substitution_mode field
  defp validate_substitution_mode(%{substitution_mode: mode})
       when mode in [:none, :always, :random] do
    :ok
  end

  defp validate_substitution_mode(%{substitution_mode: mode}) do
    {:error, "substitution_mode must be one of :none, :always, :random, got: #{inspect(mode)}"}
  end

  # Validate dictionary field
  defp validate_dictionary(%{dictionary: dict}) when is_atom(dict) do
    :ok
  end

  defp validate_dictionary(%{dictionary: dict}) do
    {:error, "dictionary must be an atom, got: #{inspect(dict)}"}
  end

  # Helper to validate allowed symbols
  defp validate_allowed_symbols(string, field_name) when is_binary(string) do
    # Empty string is allowed (means don't use separators/padding)
    if string == "" do
      :ok
    else
      graphemes = String.graphemes(string)
      # Reject letters and digits, but allow all other Unicode characters including symbols
      invalid =
        Enum.filter(graphemes, fn char ->
          String.match?(char, ~r/^[\p{L}\p{N}]$/u)
        end)

      if Enum.empty?(invalid) do
        :ok
      else
        {:error,
         "#{field_name} cannot contain letters or numbers, got: #{inspect(invalid)}. " <>
           "Only symbols and punctuation are allowed (including Unicode symbols)."}
      end
    end
  end

  @doc """
  Returns the list of allowed symbol characters.

  ## Examples

      iex> symbols = ExkPasswd.Config.Schema.allowed_symbols()
      ...> Enum.member?(symbols, "-")
      true
  """
  @spec allowed_symbols() :: [String.t()]
  def allowed_symbols, do: @allowed_symbols
end
