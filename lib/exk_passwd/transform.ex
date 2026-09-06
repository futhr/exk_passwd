defprotocol ExkPasswd.Transform do
  @moduledoc """
  Protocol for transforming selected words before separators, digits, and padding are added.

  Configure transforms with `meta: %{transforms: [...]}`. They run in list order,
  after `case_transform` and configured substitutions. Each implementation must
  return a valid UTF-8 string. Deterministic implementations must depend only on
  their arguments; entropy analysis may reuse their result for equivalent word
  positions.

  ## Built-in transforms

  - `ExkPasswd.Transform.CaseTransform` changes letter casing.
  - `ExkPasswd.Transform.Substitution` replaces graphemes using lowercase lookup keys.
  - `ExkPasswd.Transform.Pinyin` provides a limited, toneless Han-character mapping.
  - `ExkPasswd.Transform.Romaji` romanizes kana; it does not translate Kanji readings.

  ## Examples

      iex> config =
      ...>   ExkPasswd.Config.new!(
      ...>     meta: %{
      ...>       transforms: [
      ...>         %ExkPasswd.Transform.Substitution{map: %{"e" => "3"}, mode: :always}
      ...>       ]
      ...>     }
      ...>   )
      ...>
      ...> is_binary(ExkPasswd.generate(config))
      true

  ## Custom transform

  Define the struct and protocol implementation in your application's `lib/`
  directory so they are compiled before protocol consolidation:

  ```elixir
  defmodule MyApp.ReverseTransform do
    @moduledoc "Reverses each selected word."
    defstruct []

    defimpl ExkPasswd.Transform do
      def apply(_, word, _config), do: String.reverse(word)
      def entropy_bits(_, _config), do: 0.0
    end
  end
  ```

  Add `%MyApp.ReverseTransform{}` to `meta.transforms` to use it. Keep helper
  functions or lookup tables inside the implementation module, or expose them
  through the struct module: module attributes are not shared with `defimpl`.

  ## Entropy

  Return `0.0` from `entropy_bits/2` for a deterministic transform. This does
  not mean that the transform preserves entropy: different inputs may map to
  the same output. Romanization and substitutions commonly cause collisions.

  For random transforms, the callback describes nominal randomness for the
  whole password. A binary choice per word contributes `config.num_words * 1.0`
  nominal bits. The analyzer enumerates supported built-in distributions;
  it does not trust a custom callback as proof of output entropy. An unknown
  random transform causes the conservative seen estimate to be zero.

  Word-level distributions do not always compose uniquely into strings. See
  `ExkPasswd.Entropy.calculate_seen_detailed/1` for the composition deduction.
  """

  @doc """
  Apply the transformation to a selected word.

  ## Parameters

  - `transform` - The transform implementation struct
  - `component` - String to transform (typically a word)
  - `config` - The full Config struct (for context)

  ## Returns

  The transformed string.
  """
  @spec apply(t(), String.t(), ExkPasswd.Config.t()) :: String.t()
  def apply(transform, component, config)

  @doc """
  Calculate the entropy contribution of this transformation in bits.

  Return 0.0 for deterministic transforms, or describe nominal randomness for
  the whole password. Custom random callback values are not added to the
  security estimate without a known output distribution.

  ## Parameters

  - `transform` - The transform implementation struct
  - `config` - The full Config struct (for context)

  ## Returns

  Entropy in bits (float).
  """
  @spec entropy_bits(t(), ExkPasswd.Config.t()) :: float()
  def entropy_bits(transform, config)
end
