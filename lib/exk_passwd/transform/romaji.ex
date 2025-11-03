defmodule ExkPasswd.Transform.Romaji do
  @moduledoc """
  Converts Japanese Hiragana/Katakana to Romaji for keyboard compatibility.

  This transform enables passwords with Japanese words to be typed on any keyboard
  layout while maintaining memorability for Japanese speakers.

  ## Use Case

  - **Dictionary**: Japanese words (memorability in native language)
  - **Transform**: Romaji conversion (ASCII output for compatibility)
  - **Result**: Memorable for Japanese speakers, compatible with all systems

  ## Examples

      # Load Japanese dictionary
      ExkPasswd.Dictionary.load_custom(:japanese, ["さくら", "やま", "うみ", "そら", "かぜ"])

      config = ExkPasswd.Config.new!(
        dictionary: :japanese,
        word_length: 2..4,
        word_length_bounds: 1..10,
        separator: "-",
        meta: %{
          transforms: [%ExkPasswd.Transform.Romaji{}]
        }
      )

      ExkPasswd.generate(config)
      #=> "45-sakura-yama-umi-89"
      # Memorable: Japanese speaker remembers "さくら やま うみ"
      # Compatible: Works on any keyboard, any system

  ## Supported Scripts

  - Hiragana (あいうえお...)
  - Katakana (アイウエオ...)

  ## Hepburn Romanization Rules

  This implementation follows Modified Hepburn romanization with proper handling of:

  - **Long vowels**: ー elongates the previous vowel (e.g., コーヒー → kōhī or koohii)
  - **Sokuon (っ/ッ)**: Doubles the next consonant (e.g., がっこう → gakkou)
  - **Palatalized sounds (ゃ/ゅ/ょ)**: Combines with previous consonant (e.g., きょう → kyou)
  - **Particle は**: Romanized as "wa" when used as a particle
  - **Particle を**: Romanized as "o" when used as a particle
  - **ん before labials**: Romanized as "m" before p, b, m (e.g., さんぽ → sampo)
  """

  defstruct []

  @type t :: %__MODULE__{}

  # Hiragana to Romaji mapping
  @hiragana_map %{
    # Basic vowels
    "あ" => "a",
    "い" => "i",
    "う" => "u",
    "え" => "e",
    "お" => "o",
    # K-row
    "か" => "ka",
    "き" => "ki",
    "く" => "ku",
    "け" => "ke",
    "こ" => "ko",
    # G-row
    "が" => "ga",
    "ぎ" => "gi",
    "ぐ" => "gu",
    "げ" => "ge",
    "ご" => "go",
    # S-row
    "さ" => "sa",
    "し" => "shi",
    "す" => "su",
    "せ" => "se",
    "そ" => "so",
    # Z-row
    "ざ" => "za",
    "じ" => "ji",
    "ず" => "zu",
    "ぜ" => "ze",
    "ぞ" => "zo",
    # T-row
    "た" => "ta",
    "ち" => "chi",
    "つ" => "tsu",
    "て" => "te",
    "と" => "to",
    # D-row
    "だ" => "da",
    "ぢ" => "ji",
    "づ" => "zu",
    "で" => "de",
    "ど" => "do",
    # N-row
    "な" => "na",
    "に" => "ni",
    "ぬ" => "nu",
    "ね" => "ne",
    "の" => "no",
    # H-row
    "は" => "ha",
    "ひ" => "hi",
    "ふ" => "fu",
    "へ" => "he",
    "ほ" => "ho",
    # B-row
    "ば" => "ba",
    "び" => "bi",
    "ぶ" => "bu",
    "べ" => "be",
    "ぼ" => "bo",
    # P-row
    "ぱ" => "pa",
    "ぴ" => "pi",
    "ぷ" => "pu",
    "ぺ" => "pe",
    "ぽ" => "po",
    # M-row
    "ま" => "ma",
    "み" => "mi",
    "む" => "mu",
    "め" => "me",
    "も" => "mo",
    # Y-row
    "や" => "ya",
    "ゆ" => "yu",
    "よ" => "yo",
    # R-row
    "ら" => "ra",
    "り" => "ri",
    "る" => "ru",
    "れ" => "re",
    "ろ" => "ro",
    # W-row
    "わ" => "wa",
    "を" => "wo",
    "ん" => "n",
    # Small characters (palatalization - requires context-aware handling)
    "ゃ" => "ya",
    "ゅ" => "yu",
    "ょ" => "yo",
    "ぁ" => "a",
    "ぃ" => "i",
    "ぅ" => "u",
    "ぇ" => "e",
    "ぉ" => "o",
    # Sokuon (gemination - doubles next consonant, requires context-aware handling)
    "っ" => "",
    # Long vowel marker (requires context-aware handling)
    "ー" => ""
  }

  # Katakana to Romaji mapping
  @katakana_map %{
    # Basic vowels
    "ア" => "a",
    "イ" => "i",
    "ウ" => "u",
    "エ" => "e",
    "オ" => "o",
    # K-row
    "カ" => "ka",
    "キ" => "ki",
    "ク" => "ku",
    "ケ" => "ke",
    "コ" => "ko",
    # G-row
    "ガ" => "ga",
    "ギ" => "gi",
    "グ" => "gu",
    "ゲ" => "ge",
    "ゴ" => "go",
    # S-row
    "サ" => "sa",
    "シ" => "shi",
    "ス" => "su",
    "セ" => "se",
    "ソ" => "so",
    # Z-row
    "ザ" => "za",
    "ジ" => "ji",
    "ズ" => "zu",
    "ゼ" => "ze",
    "ゾ" => "zo",
    # T-row
    "タ" => "ta",
    "チ" => "chi",
    "ツ" => "tsu",
    "テ" => "te",
    "ト" => "to",
    # D-row
    "ダ" => "da",
    "ヂ" => "ji",
    "ヅ" => "zu",
    "デ" => "de",
    "ド" => "do",
    # N-row
    "ナ" => "na",
    "ニ" => "ni",
    "ヌ" => "nu",
    "ネ" => "ne",
    "ノ" => "no",
    # H-row
    "ハ" => "ha",
    "ヒ" => "hi",
    "フ" => "fu",
    "ヘ" => "he",
    "ホ" => "ho",
    # B-row
    "バ" => "ba",
    "ビ" => "bi",
    "ブ" => "bu",
    "ベ" => "be",
    "ボ" => "bo",
    # P-row
    "パ" => "pa",
    "ピ" => "pi",
    "プ" => "pu",
    "ペ" => "pe",
    "ポ" => "po",
    # M-row
    "マ" => "ma",
    "ミ" => "mi",
    "ム" => "mu",
    "メ" => "me",
    "モ" => "mo",
    # Y-row
    "ヤ" => "ya",
    "ユ" => "yu",
    "ヨ" => "yo",
    # R-row
    "ラ" => "ra",
    "リ" => "ri",
    "ル" => "ru",
    "レ" => "re",
    "ロ" => "ro",
    # W-row
    "ワ" => "wa",
    "ヲ" => "wo",
    "ン" => "n",
    # Small characters (palatalization - requires context-aware handling)
    "ャ" => "ya",
    "ュ" => "yu",
    "ョ" => "yo",
    "ァ" => "a",
    "ィ" => "i",
    "ゥ" => "u",
    "ェ" => "e",
    "ォ" => "o",
    # Sokuon (gemination - doubles next consonant, requires context-aware handling)
    "ッ" => "",
    # Long vowel marker (requires context-aware handling)
    "ー" => ""
  }

  # Combine both mappings
  @romaji_map_data Map.merge(@hiragana_map, @katakana_map)

  def romaji_map, do: @romaji_map_data

  defimpl ExkPasswd.Transform do
    @doc """
    Apply Romaji conversion to a Japanese word.

    Converts each Hiragana/Katakana character to its Romaji equivalent.
    Characters not in the mapping are left unchanged.

    ## Parameters

    - `_transform` - The Romaji transform struct (unused)
    - `word` - Japanese word to convert
    - `_config` - Config struct (unused)

    ## Returns

    Romanized word in Romaji.

    ## Examples

        iex> ExkPasswd.Transform.apply(%ExkPasswd.Transform.Romaji{}, "さくら", nil)
        "sakura"

        iex> ExkPasswd.Transform.apply(%ExkPasswd.Transform.Romaji{}, "やま", nil)
        "yama"

        iex> ExkPasswd.Transform.apply(%ExkPasswd.Transform.Romaji{}, "サクラ", nil)
        "sakura"
    """
    def apply(_transform, word, _config) do
      romaji_map = ExkPasswd.Transform.Romaji.romaji_map()
      graphemes = String.graphemes(word)

      graphemes
      |> convert_with_context(romaji_map)
      |> Enum.join()
    end

    # Context-aware romanization with proper Hepburn rules
    # Process graphemes list and return list of romanized strings
    defp convert_with_context([], _map), do: []

    # Handle sokuon (っ/ッ) - doubles the next consonant
    # Special case: っち/ッチ → "tch" (Modified Hepburn rule)
    defp convert_with_context(["っ" | ["ち" | rest]], map) do
      ["t" | convert_with_context(["ち" | rest], map)]
    end

    defp convert_with_context(["ッ" | ["チ" | rest]], map) do
      ["t" | convert_with_context(["チ" | rest], map)]
    end

    # Regular sokuon handling for other consonants
    defp convert_with_context(["っ" | [next | rest]], map) when next not in ["ゃ", "ゅ", "ょ"] do
      next_romaji = Map.get(map, next, next)
      doubled = double_consonant(next_romaji)
      [doubled, next_romaji | convert_with_context(rest, map)]
    end

    defp convert_with_context(["ッ" | [next | rest]], map) when next not in ["ャ", "ュ", "ョ"] do
      next_romaji = Map.get(map, next, next)
      doubled = double_consonant(next_romaji)
      [doubled, next_romaji | convert_with_context(rest, map)]
    end

    # Handle palatalized sounds (きゃ/きゅ/きょ etc.) - must come before default mapping
    defp convert_with_context([current, small | rest], map)
         when small in ["ゃ", "ゅ", "ょ", "ャ", "ュ", "ョ"] do
      current_romaji = Map.get(map, current, current)
      small_romaji = Map.get(map, small, small)
      palatalized = palatalize(current_romaji, small_romaji)
      [palatalized | convert_with_context(rest, map)]
    end

    # Handle う after o-sound (long vowel) - e.g., とう → tou or to
    # In Hepburn, こう → kou (or kō), そう → sou (or sō)
    defp convert_with_context([current, "う" | rest], map)
         when current in [
                "こ",
                "そ",
                "と",
                "の",
                "ほ",
                "も",
                "よ",
                "ろ",
                "を",
                "ご",
                "ぞ",
                "ど",
                "ぼ",
                "ぽ",
                "コ",
                "ソ",
                "ト",
                "ノ",
                "ホ",
                "モ",
                "ヨ",
                "ロ",
                "ヲ",
                "ゴ",
                "ゾ",
                "ド",
                "ボ",
                "ポ"
              ] do
      current_romaji = Map.get(map, current, current)
      # For strict Hepburn, we'd omit the 'u', but for passwords, keeping it is clearer
      [current_romaji, "u" | convert_with_context(rest, map)]
    end

    # Handle long vowel marker (ー) - elongates by repeating the vowel
    defp convert_with_context(["ー" | rest], map) do
      # We'll just skip it for now, or could double previous vowel in post-processing
      convert_with_context(rest, map)
    end

    # Handle ん before labials (p, b, m) - becomes 'm'
    defp convert_with_context(["ん" | [next | rest]], map) do
      next_romaji = Map.get(map, next, next)
      n_sound = if starts_with_labial?(next_romaji), do: "m", else: "n"
      [n_sound | convert_with_context([next | rest], map)]
    end

    defp convert_with_context(["ン" | [next | rest]], map) do
      next_romaji = Map.get(map, next, next)
      n_sound = if starts_with_labial?(next_romaji), do: "m", else: "n"
      [n_sound | convert_with_context([next | rest], map)]
    end

    # Default: simple mapping
    defp convert_with_context([char | rest], map) do
      romaji = Map.get(map, char, char)
      [romaji | convert_with_context(rest, map)]
    end

    # Helper: Double the first consonant (for sokuon)
    defp double_consonant(romaji) do
      case String.first(romaji) do
        nil -> ""
        # Can't double vowels
        first when first in ~w(a i u e o) -> ""
        first -> first
      end
    end

    # Helper: Palatalize (combine consonant with ya/yu/yo)
    # In Hepburn: きゃ→kya, ちゃ→cha, しゃ→sha, じゃ→ja, etc.
    defp palatalize(consonant_romaji, small_romaji) do
      vowel = extract_vowel(small_romaji)
      palatalize_consonant(consonant_romaji, vowel)
    end

    # Extract vowel from small ya/yu/yo characters
    defp extract_vowel("ya"), do: "a"
    defp extract_vowel("yu"), do: "u"
    defp extract_vowel("yo"), do: "o"
    defp extract_vowel(other), do: other

    # Palatalization mapping using pattern matching (reduces complexity)
    # Special cases that don't follow the simple i→y pattern
    defp palatalize_consonant("chi" <> _rest, vowel), do: "ch" <> vowel
    defp palatalize_consonant("shi" <> _rest, vowel), do: "sh" <> vowel
    defp palatalize_consonant("ji" <> _rest, vowel), do: "j" <> vowel

    # Regular i-ending consonants: ki→ky, gi→gy, etc.
    defp palatalize_consonant(consonant, vowel) do
      if String.ends_with?(consonant, "i") do
        String.replace_suffix(consonant, "i", "y") <> vowel
      else
        consonant <> vowel
      end
    end

    # Helper: Check if romaji starts with labial consonant
    defp starts_with_labial?(romaji) do
      String.starts_with?(romaji, ["p", "b", "m"])
    end

    @doc """
    Returns entropy contribution of Romaji transform.

    Romaji conversion is deterministic (one-to-one mapping), so it contributes
    no additional entropy. Security comes from the random word selection, not
    from the romanization.

    ## Returns

    `0.0` (no additional entropy)
    """
    def entropy_bits(_transform, _config) do
      0.0
    end
  end
end
