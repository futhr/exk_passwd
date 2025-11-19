defmodule ExkPasswd.Transform.Substitution do
  @moduledoc """
  Character substitution transformation (leetspeak-style).

  This transform replaces characters with symbols or numbers:
  - `a` → `@`
  - `e` → `3`
  - `i` → `!`
  - `o` → `0`
  - `s` → `$`

  ## Modes

  - `:none` - No substitutions
  - `:always` - Always apply substitutions (deterministic, no entropy)
  - `:random` - Randomly apply per word (adds 1 bit entropy per word)

  ## Examples

      subs = %{"e" => "3", "o" => "0"}
      transform = %ExkPasswd.Transform.Substitution{map: subs, mode: :always}
      ExkPasswd.Transform.apply(transform, "hello", config)
      #=> "h3ll0"

      transform = %ExkPasswd.Transform.Substitution{map: subs, mode: :random}
      ExkPasswd.Transform.apply(transform, "hello", config)
      #=> "h3ll0" or "hello" (random)
  """

  alias ExkPasswd.Random

  defstruct map: %{}, mode: :none

  @type mode :: :none | :always | :random

  @type t :: %__MODULE__{
          map: %{String.t() => String.t()},
          mode: mode()
        }

  @default_substitutions %{
    "a" => "@",
    "e" => "3",
    "i" => "!",
    "o" => "0",
    "s" => "$",
    "l" => "1",
    "t" => "7"
  }

  @doc """
  Returns the default character substitution map.

  ## Examples

      iex> subs = ExkPasswd.Transform.Substitution.default_substitutions()
      ...> Map.get(subs, "e")
      "3"
  """
  @spec default_substitutions() :: map()
  def default_substitutions, do: @default_substitutions

  defimpl ExkPasswd.Transform do
    def apply(%{mode: :none}, word, _config), do: word

    def apply(%{map: subs, mode: :always}, word, _config) do
      substitute_characters(word, subs)
    end

    def apply(%{map: subs, mode: :random}, word, _config) do
      if Random.boolean() do
        substitute_characters(word, subs)
      else
        word
      end
    end

    # Entropy calculation
    def entropy_bits(%{mode: :random}, config) do
      # Each word adds 1 bit (substituted or not)
      config.num_words * 1.0
    end

    def entropy_bits(_, _config) do
      # Deterministic or no substitution = no entropy
      0.0
    end

    # Private helper to perform actual substitution
    defp substitute_characters(word, substitutions) do
      word
      |> String.graphemes()
      |> Enum.map(fn char ->
        lowercase_char = String.downcase(char)

        case Map.get(substitutions, lowercase_char) do
          nil -> char
          replacement -> replacement
        end
      end)
      |> Enum.join()
    end
  end

  @doc """
  Calculate how many substitutable characters exist in a word.

  Useful for entropy calculations and analysis.

  ## Parameters

  - `word` - The word to analyze
  - `substitutions` - Map of character substitutions

  ## Returns

  Count of substitutable characters.

  ## Examples

      iex> ExkPasswd.Transform.Substitution.count_substitutable("hello", %{
      ...>   "e" => "3",
      ...>   "l" => "1",
      ...>   "o" => "0"
      ...> })
      4
  """
  @spec count_substitutable(String.t(), map()) :: non_neg_integer()
  def count_substitutable(word, substitutions) do
    word
    |> String.graphemes()
    |> Enum.count(fn char ->
      Map.has_key?(substitutions, String.downcase(char))
    end)
  end
end
