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

  ## Limitations

  - Long vowels in Katakana (ー) are represented as repeated vowels (aa, ii)
  - Small っ (sokuon) is represented as double consonant
  - Characters not in the mapping are left unchanged
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
    # Small characters
    "ゃ" => "ya",
    "ゅ" => "yu",
    "ょ" => "yo",
    "っ" => "",
    # Combining marks
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
    # Small characters
    "ャ" => "ya",
    "ュ" => "yu",
    "ョ" => "yo",
    "ッ" => "",
    # Long vowel marker
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

      word
      |> String.graphemes()
      |> Enum.map(fn char -> Map.get(romaji_map, char, char) end)
      |> Enum.join()
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
