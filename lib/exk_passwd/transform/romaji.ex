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

      # Katakana loanwords are also supported
      ExkPasswd.Dictionary.load_custom(:katakana, ["ファイル", "コーヒー", "パーティー"])
      # Converts to: fairu, koohii, paatii

  ## Supported Scripts

  - **Hiragana** (あいうえお...) - All standard characters
  - **Katakana** (アイウエオ...) - All standard characters plus extended sounds
  - **Extended Katakana** - Foreign sound combinations (ファ, ウィ, ヴァ, ティ, etc.)

  ## Romanization Style

  This implementation follows **Modified Hepburn with Wāpuro input conventions**,
  which matches how Japanese speakers type on QWERTY keyboards using IME (Input Method Editor).

  ### Standard Hepburn Features

  - **Sokuon (っ/ッ)**: Doubles the next consonant
    - がっこう → gakkou
    - まっちゃ → matcha (special case: っち → tch)
  - **Palatalized sounds (ゃ/ゅ/ょ)**: Combines with previous consonant
    - きょう → kyou, しゃ → sha, ちゃ → cha
  - **ん before labials**: Romanized as "m" before p, b, m
    - さんぽ → sampo, しんぶん → shimbun

  ### Extended Features (Katakana Loanwords)

  - **Long vowel marker (ー)**: Duplicates the previous vowel for ASCII compatibility
    - コーヒー → koohii (not kōhī with macrons)
    - ラーメン → raamen, ビール → biiru
  - **ヴ (vu) sound**: Used for "v" in foreign words
    - ヴァイオリン → vaiorin (violin)
    - ヴ → vu, ヴァ → va, ヴィ → vi, ヴェ → ve, ヴォ → vo
  - **Small vowel combinations**: Used for foreign sounds
    - フ + small vowels: ファ → fa, フィ → fi, フェ → fe, フォ → fo
    - ウ + small vowels: ウィ → wi, ウェ → we, ウォ → wo
    - テ/デ + small イ: ティ → ti, ディ → di
    - ト/ド + small ウ: トゥ → tu, ドゥ → du
    - シ/チ/ジ + small エ: シェ → she, チェ → che, ジェ → je

  ### Real-World Examples

      ExkPasswd.Transform.apply(%Romaji{}, "ファイル", nil)     #=> "fairu" (file)
      ExkPasswd.Transform.apply(%Romaji{}, "パーティー", nil)   #=> "paatii" (party)
      ExkPasswd.Transform.apply(%Romaji{}, "ウィンドウ", nil)   #=> "windou" (window)
      ExkPasswd.Transform.apply(%Romaji{}, "チェック", nil)     #=> "chekku" (check)
      ExkPasswd.Transform.apply(%Romaji{}, "コンピューター", nil) #=> "kompyuutaa" (computer)

  ## Limitations

  ### Kanji Not Supported

  This transform **cannot convert Kanji (漢字)** to romaji without additional
  morphological analysis or dictionary lookup. Kanji characters will be passed
  through unchanged.

  To use Japanese words with Kanji:
  1. Pre-convert to Hiragana/Katakana using your system IME or online tools
  2. Use kana-only dictionaries
  3. Use the `contains_kanji?/1` function to detect Kanji in input

  ### Particle Handling

  The transform does not distinguish grammatical particles (は as "wa", を as "o")
  from their regular usage, as this requires sentence-level context. For password
  generation from word lists, this distinction is not necessary.

  ## Kanji Detection

  Use `contains_kanji?/1` to check if text contains Kanji characters:

      ExkPasswd.Transform.Romaji.contains_kanji?("桜")      #=> true
      ExkPasswd.Transform.Romaji.contains_kanji?("さくら")  #=> false
      ExkPasswd.Transform.Romaji.contains_kanji?("日本語")  #=> true
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
    # V-row (used for foreign words)
    "ヴ" => "vu",
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

  # Small vowel kana (used for foreign loanword sounds in Katakana)
  @small_vowels_hiragana ["ぁ", "ぃ", "ぅ", "ぇ", "ぉ"]
  @small_vowels_katakana ["ァ", "ィ", "ゥ", "ェ", "ォ"]
  @small_vowels @small_vowels_hiragana ++ @small_vowels_katakana

  def romaji_map, do: @romaji_map_data

  @doc """
  Check if a character is a small vowel kana.

  Small vowels are used in Katakana to represent foreign sounds like ファ (fa), ウィ (wi), etc.
  """
  @spec small_vowel?(String.t()) :: boolean()
  def small_vowel?(char), do: char in @small_vowels

  @doc """
  Get the vowel value from a small vowel kana.

  ## Examples

      iex> ExkPasswd.Transform.Romaji.get_small_vowel_value("ァ")
      "a"

      iex> ExkPasswd.Transform.Romaji.get_small_vowel_value("ぃ")
      "i"
  """
  @spec get_small_vowel_value(String.t()) :: String.t()
  def get_small_vowel_value("ぁ"), do: "a"
  def get_small_vowel_value("ァ"), do: "a"
  def get_small_vowel_value("ぃ"), do: "i"
  def get_small_vowel_value("ィ"), do: "i"
  def get_small_vowel_value("ぅ"), do: "u"
  def get_small_vowel_value("ゥ"), do: "u"
  def get_small_vowel_value("ぇ"), do: "e"
  def get_small_vowel_value("ェ"), do: "e"
  def get_small_vowel_value("ぉ"), do: "o"
  def get_small_vowel_value("ォ"), do: "o"
  def get_small_vowel_value(_), do: ""

  @doc """
  Check if a string contains Kanji characters.

  Kanji are Chinese characters used in Japanese writing. This transform cannot
  convert Kanji to romaji without additional dictionary/morphological analysis.

  ## Kanji Unicode Ranges

  - CJK Unified Ideographs: U+4E00 to U+9FFF (most common Kanji)
  - CJK Extension A: U+3400 to U+4DBF
  - CJK Extension B+: U+20000 to U+2EBEF (rare, requires surrogate pairs)

  ## Examples

      iex> ExkPasswd.Transform.Romaji.contains_kanji?("さくら")
      false

      iex> ExkPasswd.Transform.Romaji.contains_kanji?("桜")
      true

      iex> ExkPasswd.Transform.Romaji.contains_kanji?("日本語")
      true

      iex> ExkPasswd.Transform.Romaji.contains_kanji?("コーヒー")
      false
  """
  @spec contains_kanji?(String.t()) :: boolean()
  def contains_kanji?(text) do
    String.graphemes(text)
    |> Enum.any?(&kanji?/1)
  end

  @doc """
  Check if a single character is a Kanji character.

  ## Examples

      iex> ExkPasswd.Transform.Romaji.kanji?("桜")
      true

      iex> ExkPasswd.Transform.Romaji.kanji?("さ")
      false

      iex> ExkPasswd.Transform.Romaji.kanji?("日")
      true
  """
  @spec kanji?(String.t()) :: boolean()
  def kanji?(char) when byte_size(char) == 0, do: false

  def kanji?(char) do
    # Get the Unicode codepoint of the first character
    case String.to_charlist(char) do
      [codepoint | _] ->
        # Check if codepoint is in Kanji ranges
        (codepoint >= 0x4E00 and codepoint <= 0x9FFF) or
          (codepoint >= 0x3400 and codepoint <= 0x4DBF) or
          (codepoint >= 0x20000 and codepoint <= 0x2EBEF)

      [] ->
        false
    end
  rescue
    # If we can't decode the character, assume it's not Kanji
    _ -> false
  end

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
      |> convert_with_context(romaji_map, "")
      |> elem(0)
    end

    # Context-aware romanization with proper Hepburn rules
    # Process graphemes list and return {result_string, accumulated} tuple
    # The accumulated parameter tracks what we've built so far for context-aware decisions
    defp convert_with_context([], _map, accumulated), do: {accumulated, accumulated}

    # Handle sokuon (っ/ッ) - doubles the next consonant
    # Special case: っちゃ/っちゅ/っちょ → "tcha/tchu/tcho" (Modified Hepburn rule)
    defp convert_with_context(["っ", "ち", small | rest], map, acc)
         when small in ["ゃ", "ゅ", "ょ"] do
      # Handle っち followed by small ya/yu/yo as palatalized: tcha, tchu, tcho
      small_romaji = Map.get(map, small, small)
      palatalized = palatalize("chi", small_romaji)
      new_acc = acc <> "t" <> palatalized
      convert_with_context(rest, map, new_acc)
    end

    defp convert_with_context(["ッ", "チ", small | rest], map, acc)
         when small in ["ャ", "ュ", "ョ"] do
      # Handle ッチ followed by small ya/yu/yo as palatalized: tcha, tchu, tcho
      small_romaji = Map.get(map, small, small)
      palatalized = palatalize("chi", small_romaji)
      new_acc = acc <> "t" <> palatalized
      convert_with_context(rest, map, new_acc)
    end

    # Special case: っち/ッチ → "tch" (Modified Hepburn rule) - when not followed by palatalization
    defp convert_with_context(["っ" | ["ち" | rest]], map, acc) do
      chi_romaji = Map.get(map, "ち", "chi")
      new_acc = acc <> "t" <> chi_romaji
      convert_with_context(rest, map, new_acc)
    end

    defp convert_with_context(["ッ" | ["チ" | rest]], map, acc) do
      chi_romaji = Map.get(map, "チ", "chi")
      new_acc = acc <> "t" <> chi_romaji
      convert_with_context(rest, map, new_acc)
    end

    # Regular sokuon handling for other consonants
    defp convert_with_context(["っ" | [next | rest]], map, acc) when next not in ["ゃ", "ゅ", "ょ"] do
      next_romaji = Map.get(map, next, next)
      doubled = double_consonant(next_romaji)
      new_acc = acc <> doubled <> next_romaji
      convert_with_context(rest, map, new_acc)
    end

    defp convert_with_context(["ッ" | [next | rest]], map, acc) when next not in ["ャ", "ュ", "ョ"] do
      next_romaji = Map.get(map, next, next)
      doubled = double_consonant(next_romaji)
      new_acc = acc <> doubled <> next_romaji
      convert_with_context(rest, map, new_acc)
    end

    # Handle small vowel combinations (ファ→fa, ウィ→wi, ティ→ti, etc.)
    # These are used primarily in Katakana for foreign loanwords
    # Must come before palatalization handling
    defp convert_with_context([current, small | rest], map, acc)
         when small in ["ぁ", "ぃ", "ぅ", "ぇ", "ぉ", "ァ", "ィ", "ゥ", "ェ", "ォ"] do
      current_romaji = Map.get(map, current, current)
      small_vowel = ExkPasswd.Transform.Romaji.get_small_vowel_value(small)
      combined = combine_with_small_vowel(current, current_romaji, small_vowel)
      new_acc = acc <> combined
      convert_with_context(rest, map, new_acc)
    end

    # Handle palatalized sounds (きゃ/きゅ/きょ etc.) - must come before default mapping
    defp convert_with_context([current, small | rest], map, acc)
         when small in ["ゃ", "ゅ", "ょ", "ャ", "ュ", "ョ"] do
      current_romaji = Map.get(map, current, current)
      small_romaji = Map.get(map, small, small)
      palatalized = palatalize(current_romaji, small_romaji)
      new_acc = acc <> palatalized
      convert_with_context(rest, map, new_acc)
    end

    # Handle う after o-sound (long vowel) - e.g., とう → tou or to
    # In Hepburn, こう → kou (or kō), そう → sou (or sō)
    defp convert_with_context([current, "う" | rest], map, acc)
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
      new_acc = acc <> current_romaji <> "u"
      convert_with_context(rest, map, new_acc)
    end

    # Handle long vowel marker (ー) - elongates by repeating the last vowel
    # E.g., コーヒー → koohii (not kohi)
    defp convert_with_context(["ー" | rest], map, acc) do
      # Find the last vowel in accumulated romaji and duplicate it
      duplicated_vowel = get_last_vowel(acc)
      new_acc = acc <> duplicated_vowel
      convert_with_context(rest, map, new_acc)
    end

    # Handle ん before labials (p, b, m) - becomes 'm'
    defp convert_with_context(["ん" | [next | rest]], map, acc) do
      next_romaji = Map.get(map, next, next)
      n_sound = if starts_with_labial?(next_romaji), do: "m", else: "n"
      new_acc = acc <> n_sound
      convert_with_context([next | rest], map, new_acc)
    end

    defp convert_with_context(["ン" | [next | rest]], map, acc) do
      next_romaji = Map.get(map, next, next)
      n_sound = if starts_with_labial?(next_romaji), do: "m", else: "n"
      new_acc = acc <> n_sound
      convert_with_context([next | rest], map, new_acc)
    end

    # Default: simple mapping
    defp convert_with_context([char | rest], map, acc) do
      romaji = Map.get(map, char, char)
      new_acc = acc <> romaji
      convert_with_context(rest, map, new_acc)
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

    # Helper: Get the last vowel from accumulated romaji string for long vowel marker
    # Used to duplicate vowels when encountering ー
    # E.g., "ko" → "o", "sakura" → "a"
    defp get_last_vowel(acc) when byte_size(acc) == 0, do: ""

    defp get_last_vowel(acc) do
      # Scan backwards through the string to find the last vowel
      acc
      |> String.graphemes()
      |> Enum.reverse()
      |> Enum.find("", fn char -> char in ~w(a i u e o) end)
    end

    # Helper: Combine a kana with a small vowel for foreign sound representation
    # This handles patterns like ファ→fa, ウィ→wi, ティ→ti, etc.
    # Based on Modified Hepburn and Wāpuro romaji input conventions

    # フ/ふ + small vowel → f + vowel (ファ→fa, フィ→fi, フェ→fe, フォ→fo)
    defp combine_with_small_vowel(current, "fu", vowel) when current in ["フ", "ふ"] do
      "f" <> vowel
    end

    # ヴ + small vowel → v + vowel (ヴァ→va, ヴィ→vi, ヴェ→ve, ヴォ→vo)
    defp combine_with_small_vowel("ヴ", "vu", vowel) do
      "v" <> vowel
    end

    # ウ/う + small イ/エ/オ → w + vowel (ウィ→wi, ウェ→we, ウォ→wo)
    # Note: ウァ and ウゥ are rare/non-standard, but we handle them consistently
    defp combine_with_small_vowel(current, "u", vowel) when current in ["ウ", "う"] do
      "w" <> vowel
    end

    # テ/て + small イ → ti (ティ→ti, as in パーティー party)
    defp combine_with_small_vowel(current, "te", "i") when current in ["テ", "て"] do
      "ti"
    end

    # デ/で + small イ → di (ディ→di, as in ディスク disk)
    defp combine_with_small_vowel(current, "de", "i") when current in ["デ", "で"] do
      "di"
    end

    # ト/と + small ウ → tu (トゥ→tu)
    defp combine_with_small_vowel(current, "to", "u") when current in ["ト", "と"] do
      "tu"
    end

    # ド/ど + small ウ → du (ドゥ→du)
    defp combine_with_small_vowel(current, "do", "u") when current in ["ド", "ど"] do
      "du"
    end

    # シ/し + small エ → she (シェ→she, as in シェア share)
    defp combine_with_small_vowel(current, "shi", "e") when current in ["シ", "し"] do
      "she"
    end

    # チ/ち + small エ → che (チェ→che, as in チェック check)
    defp combine_with_small_vowel(current, "chi", "e") when current in ["チ", "ち"] do
      "che"
    end

    # ジ/じ + small エ → je (ジェ→je)
    defp combine_with_small_vowel(current, "ji", "e") when current in ["ジ", "じ"] do
      "je"
    end

    # Default: If no special rule applies, just append (for completeness)
    # This handles edge cases and ensures we always return a valid result
    defp combine_with_small_vowel(_current, romaji, vowel) do
      # For most cases, this shouldn't be reached, but we handle it gracefully
      # by simply appending the vowel
      romaji <> vowel
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
