defprotocol ExkPasswd.Transform do
  @moduledoc """
  Protocol for custom password transformations.

  Implement this protocol to create custom transformation logic that can be
  applied during password generation. Transformations can modify words,
  add complexity, or apply custom rules.

  ## Built-in Transforms

  ExkPasswd includes two built-in transforms:
  - `ExkPasswd.Transform.Substitution` - Character substitutions (leetspeak)
  - `ExkPasswd.Transform.CaseTransform` - Case transformations

  ## Usage

  Add transforms to your config via the `:meta` field:

      config = ExkPasswd.Config.new!(
        num_words: 4,
        separator: "-",
        meta: %{
          transforms: [
            %ExkPasswd.Transform.Substitution{
              map: %{"e" => "3", "o" => "0"},
              mode: :random
            }
          ]
        }
      )

      ExkPasswd.generate(config)
      #=> "h3ll0-W0RLD-t3st-PASS" (with random substitutions)

  ## Custom Transform Example 1: Japanese Romaji Transform

  Use case: Japanese users typing passwords on English keyboards.

      defmodule MyApp.RomajiTransform do
        @moduledoc \"\"\"
        Converts Japanese hiragana/katakana to romaji for keyboard portability.

        Enables passwords created on Japanese keyboard layouts to be typed on
        English QWERTY keyboards (e.g., international travel, shared workstations).
        \"\"\"
        defstruct [:mode]  # :hiragana | :katakana | :mixed

        # Romaji conversion tables (simplified for example)
        @hiragana_to_romaji %{
          "あ" => "a", "い" => "i", "う" => "u", "え" => "e", "お" => "o",
          "か" => "ka", "き" => "ki", "く" => "ku", "け" => "ke", "こ" => "ko",
          "さ" => "sa", "し" => "shi", "す" => "su", "せ" => "se", "そ" => "so"
        }

        defimpl ExkPasswd.Transform do
          def apply(%{mode: _mode}, word, _config) do
            # Convert any Japanese characters to romaji
            @hiragana_to_romaji
            |> Enum.reduce(word, fn {japanese, romaji}, acc ->
              String.replace(acc, japanese, romaji)
            end)
          end

          def entropy_bits(%{mode: _mode}, _config) do
            # Romaji conversion is deterministic, no additional entropy
            # However, it enables cross-keyboard compatibility without security loss
            0.0
          end
        end
      end

      # Use it with Japanese dictionary
      ExkPasswd.Dictionary.load_custom(:japanese, ["さくら", "やま", "うみ"])

      config = ExkPasswd.Config.new!(
        num_words: 2,
        dictionary: :japanese,
        separator: "-",
        meta: %{
          transforms: [%MyApp.RomajiTransform{mode: :hiragana}]
        }
      )

      ExkPasswd.generate(config)
      #=> "45-sakura-yama-89"  # Typeable on any keyboard

  ## Custom Transform Example 2: Prefix/Suffix Transform

      defmodule MyApp.AffixTransform do
        @moduledoc "Add prefixes or suffixes to words"
        defstruct prefix: "", suffix: ""

        defimpl ExkPasswd.Transform do
          def apply(%{prefix: pre, suffix: suf}, word, _config) do
            pre <> word <> suf
          end

          def entropy_bits(_, _config) do
            # Deterministic transform, no entropy
            0.0
          end
        end
      end

      # Use it
      config = ExkPasswd.Config.new!(
        num_words: 3,
        separator: "_",
        meta: %{
          transforms: [
            %MyApp.AffixTransform{prefix: "[", suffix: "]"}
          ]
        }
      )

      ExkPasswd.generate(config)
      #=> "[hello]_[WORLD]_[test]"

  ## Custom Transform Example 3: Unicode Normalization

      defmodule MyApp.NormalizeTransform do
        @moduledoc "Normalize unicode to ASCII-safe characters"
        defstruct [:form]

        defimpl ExkPasswd.Transform do
          def apply(%{form: form}, word, _config) do
            :unicode.characters_to_nfd_binary(word)
            |> String.replace(~r/[^\\x00-\\x7F]/, "")
          end

          def entropy_bits(_, _config), do: 0.0
        end
      end

  ## Combining Multiple Transforms

  Transforms are applied in order, so you can chain them:

      config = ExkPasswd.Config.new!(
        num_words: 4,
        meta: %{
          transforms: [
            %ExkPasswd.Transform.CaseTransform{mode: :upper},
            %ExkPasswd.Transform.Substitution{
              map: %{"E" => "3", "O" => "0"},
              mode: :always
            },
            %MyApp.AffixTransform{prefix: ">>", suffix: "<<"}
          ]
        }
      )

      ExkPasswd.generate(config)
      #=> ">>H3LL0<<->>W0RLD<<->>T3ST<<->>PASS<<"

  ## Entropy Considerations

  The `entropy_bits/2` callback is critical for accurate strength analysis:
  - Return 0.0 for deterministic transforms (always the same output)
  - Calculate bits for random transforms based on possibilities
  - Random binary choice (yes/no): 1 bit per word
  - Random N choices: log2(N) bits per word
  - Independent random per character: sum across all characters

  ## See Also

  - `ExkPasswd.Transform.Substitution` - Character substitution implementation
  - `ExkPasswd.Transform.CaseTransform` - Case transformation implementation
  - `ExkPasswd.Config` - Configuration structure with meta field
  """

  @doc """
  Apply the transformation to a password component (word or full password).

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

  This is used for password strength analysis. Return 0.0 for deterministic
  transforms, or calculate based on the randomness introduced.

  ## Parameters

  - `transform` - The transform implementation struct
  - `config` - The full Config struct (for context)

  ## Returns

  Entropy in bits (float).
  """
  @spec entropy_bits(t(), ExkPasswd.Config.t()) :: float()
  def entropy_bits(transform, config)
end
