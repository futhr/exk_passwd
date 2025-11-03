defmodule ExkPasswd.Transform.RomajiTest do
  @moduledoc """
  Comprehensive tests for Japanese Hiragana/Katakana to Romaji transformation.

  Tests cover:
  - Basic hiragana and katakana character conversion
  - Palatalization (きゃ → kya)
  - Sokuon/gemination (っ → doubled consonants)
  - Long vowels (おう → ou/oo)
  - N-sound (ん → n/m)
  - Edge cases and real-world Japanese words
  """
  use ExUnit.Case, async: true
  doctest ExkPasswd.Transform.Romaji

  alias ExkPasswd.Transform.Romaji

  @transform %Romaji{}

  describe "basic hiragana conversion" do
    test "converts vowels correctly" do
      assert ExkPasswd.Transform.apply(@transform, "あいうえお", nil) == "aiueo"
    end

    test "converts k-row correctly" do
      assert ExkPasswd.Transform.apply(@transform, "かきくけこ", nil) == "kakikukeko"
    end

    test "converts s-row correctly" do
      assert ExkPasswd.Transform.apply(@transform, "さしすせそ", nil) == "sashisuseso"
    end

    test "converts t-row correctly" do
      assert ExkPasswd.Transform.apply(@transform, "たちつてと", nil) == "tachitsuteto"
    end

    test "converts n-row correctly" do
      assert ExkPasswd.Transform.apply(@transform, "なにぬねの", nil) == "naninuneno"
    end

    test "converts m-row correctly" do
      assert ExkPasswd.Transform.apply(@transform, "まみむめも", nil) == "mamimumemo"
    end

    test "converts y-row correctly" do
      assert ExkPasswd.Transform.apply(@transform, "やゆよ", nil) == "yayuyo"
    end

    test "converts r-row correctly" do
      assert ExkPasswd.Transform.apply(@transform, "らりるれろ", nil) == "rarirurero"
    end

    test "converts w-row and n correctly" do
      assert ExkPasswd.Transform.apply(@transform, "わをん", nil) == "wawon"
    end
  end

  describe "basic katakana conversion" do
    test "converts katakana vowels correctly" do
      assert ExkPasswd.Transform.apply(@transform, "アイウエオ", nil) == "aiueo"
    end

    test "converts katakana k-row correctly" do
      assert ExkPasswd.Transform.apply(@transform, "カキクケコ", nil) == "kakikukeko"
    end

    test "converts mixed katakana correctly" do
      assert ExkPasswd.Transform.apply(@transform, "サクラ", nil) == "sakura"
    end
  end

  describe "palatalization (ya/yu/yo combinations)" do
    test "converts きゃ/きゅ/きょ correctly" do
      assert ExkPasswd.Transform.apply(@transform, "きゃ", nil) == "kya"
      assert ExkPasswd.Transform.apply(@transform, "きゅ", nil) == "kyu"
      assert ExkPasswd.Transform.apply(@transform, "きょ", nil) == "kyo"
    end

    test "converts ちゃ/ちゅ/ちょ to cha/chu/cho" do
      assert ExkPasswd.Transform.apply(@transform, "ちゃ", nil) == "cha"
      assert ExkPasswd.Transform.apply(@transform, "ちゅ", nil) == "chu"
      assert ExkPasswd.Transform.apply(@transform, "ちょ", nil) == "cho"
    end

    test "converts しゃ/しゅ/しょ to sha/shu/sho" do
      assert ExkPasswd.Transform.apply(@transform, "しゃ", nil) == "sha"
      assert ExkPasswd.Transform.apply(@transform, "しゅ", nil) == "shu"
      assert ExkPasswd.Transform.apply(@transform, "しょ", nil) == "sho"
    end

    test "converts じゃ/じゅ/じょ to ja/ju/jo" do
      assert ExkPasswd.Transform.apply(@transform, "じゃ", nil) == "ja"
      assert ExkPasswd.Transform.apply(@transform, "じゅ", nil) == "ju"
      assert ExkPasswd.Transform.apply(@transform, "じょ", nil) == "jo"
    end

    test "converts にゃ/にゅ/にょ correctly" do
      assert ExkPasswd.Transform.apply(@transform, "にゃ", nil) == "nya"
      assert ExkPasswd.Transform.apply(@transform, "にゅ", nil) == "nyu"
      assert ExkPasswd.Transform.apply(@transform, "にょ", nil) == "nyo"
    end

    test "converts りゃ/りゅ/りょ correctly" do
      assert ExkPasswd.Transform.apply(@transform, "りゃ", nil) == "rya"
      assert ExkPasswd.Transform.apply(@transform, "りゅ", nil) == "ryu"
      assert ExkPasswd.Transform.apply(@transform, "りょ", nil) == "ryo"
    end

    test "converts ぎゃ/ぎゅ/ぎょ correctly (katakana versions)" do
      assert ExkPasswd.Transform.apply(@transform, "ギャ", nil) == "gya"
      assert ExkPasswd.Transform.apply(@transform, "ギュ", nil) == "gyu"
      assert ExkPasswd.Transform.apply(@transform, "ギョ", nil) == "gyo"
    end

    test "converts びゃ/びゅ/びょ correctly" do
      assert ExkPasswd.Transform.apply(@transform, "びゃ", nil) == "bya"
      assert ExkPasswd.Transform.apply(@transform, "びゅ", nil) == "byu"
      assert ExkPasswd.Transform.apply(@transform, "びょ", nil) == "byo"
    end

    test "converts ぴゃ/ぴゅ/ぴょ correctly" do
      assert ExkPasswd.Transform.apply(@transform, "ぴゃ", nil) == "pya"
      assert ExkPasswd.Transform.apply(@transform, "ぴゅ", nil) == "pyu"
      assert ExkPasswd.Transform.apply(@transform, "ぴょ", nil) == "pyo"
    end

    test "converts みゃ/みゅ/みょ correctly" do
      assert ExkPasswd.Transform.apply(@transform, "みゃ", nil) == "mya"
      assert ExkPasswd.Transform.apply(@transform, "みゅ", nil) == "myu"
      assert ExkPasswd.Transform.apply(@transform, "みょ", nil) == "myo"
    end

    test "converts small ぁ/ぃ/ぅ/ぇ/ぉ characters" do
      # Test small vowels (which can appear in some contexts)
      assert ExkPasswd.Transform.apply(@transform, "ぁ", nil) == "a"
      assert ExkPasswd.Transform.apply(@transform, "ぃ", nil) == "i"
      assert ExkPasswd.Transform.apply(@transform, "ぅ", nil) == "u"
      assert ExkPasswd.Transform.apply(@transform, "ぇ", nil) == "e"
      assert ExkPasswd.Transform.apply(@transform, "ぉ", nil) == "o"
    end

    test "converts katakana small vowels" do
      assert ExkPasswd.Transform.apply(@transform, "ァ", nil) == "a"
      assert ExkPasswd.Transform.apply(@transform, "ィ", nil) == "i"
      assert ExkPasswd.Transform.apply(@transform, "ゥ", nil) == "u"
      assert ExkPasswd.Transform.apply(@transform, "ェ", nil) == "e"
      assert ExkPasswd.Transform.apply(@transform, "ォ", nil) == "o"
    end
  end

  describe "sokuon (っ/ッ) - gemination" do
    test "doubles consonants after っ" do
      assert ExkPasswd.Transform.apply(@transform, "がっこう", nil) == "gakkou"
      assert ExkPasswd.Transform.apply(@transform, "ざっし", nil) == "zasshi"
      assert ExkPasswd.Transform.apply(@transform, "きっぷ", nil) == "kippu"
    end

    test "doubles consonants after ッ in katakana" do
      assert ExkPasswd.Transform.apply(@transform, "サッカー", nil) == "sakka"
    end

    test "special case: っち → tch (Modified Hepburn)" do
      # Modified Hepburn romanization: っち is special case → tch not cch
      assert ExkPasswd.Transform.apply(@transform, "っち", nil) == "tchi"
      assert ExkPasswd.Transform.apply(@transform, "こっち", nil) == "kotchi"
      assert ExkPasswd.Transform.apply(@transform, "まっちゃ", nil) == "matcha"
      assert ExkPasswd.Transform.apply(@transform, "ッチ", nil) == "tchi"
    end

    test "sokuon followed by palatalized sounds" do
      # Test っ followed by small ya/yu/yo (should not double)
      # This tests the guard: when next not in ["ゃ", "ゅ", "ょ"]
      assert ExkPasswd.Transform.apply(@transform, "ちょっと", nil) == "chotto"
    end

    test "katakana sokuon followed by palatalized sounds" do
      # Similar for katakana: ッ followed by ャ/ュ/ョ
      assert ExkPasswd.Transform.apply(@transform, "チョット", nil) == "chotto"
    end

    test "works with complex words" do
      # hokkaido - the 'っ' doubles the 'k'
      result = ExkPasswd.Transform.apply(@transform, "ほっかいどう", nil)
      assert result == "hokkaidou" or result == "hokkaido"
    end
  end

  describe "long vowels" do
    test "handles ou combinations" do
      # In Hepburn, ou after o-sound can be romanized as 'ou' or 'o'
      # We keep 'ou' for clarity in passwords
      assert ExkPasswd.Transform.apply(@transform, "とうきょう", nil) == "toukyou"
      assert ExkPasswd.Transform.apply(@transform, "おおさか", nil) == "oosaka"
    end

    test "handles katakana long vowel marker ー" do
      result = ExkPasswd.Transform.apply(@transform, "コーヒー", nil)
      # Long vowel marker is skipped for now
      assert result == "kohi" or result == "koohii"
    end
  end

  describe "n before labials" do
    test "converts ん to m before p, b, m" do
      assert ExkPasswd.Transform.apply(@transform, "さんぽ", nil) == "sampo"
      assert ExkPasswd.Transform.apply(@transform, "しんぶん", nil) == "shimbun"
      assert ExkPasswd.Transform.apply(@transform, "かんぱい", nil) == "kampai"
    end

    test "keeps ん as n before other consonants" do
      assert ExkPasswd.Transform.apply(@transform, "せんせい", nil) == "sensei"
      assert ExkPasswd.Transform.apply(@transform, "てんき", nil) == "tenki"
    end
  end

  describe "real Japanese words" do
    test "converts common words correctly" do
      assert ExkPasswd.Transform.apply(@transform, "さくら", nil) == "sakura"
      assert ExkPasswd.Transform.apply(@transform, "やま", nil) == "yama"
      assert ExkPasswd.Transform.apply(@transform, "うみ", nil) == "umi"
      assert ExkPasswd.Transform.apply(@transform, "そら", nil) == "sora"
      assert ExkPasswd.Transform.apply(@transform, "かぜ", nil) == "kaze"
    end

    test "converts user-reported test cases correctly from ANALYSIS.md" do
      # From ANALYSIS.md line 63-68 - these were originally broken with simple character mapping
      # ほっかいどう → hokaidou (expected: hokkaido) - FIXED with sokuon handling
      result = ExkPasswd.Transform.apply(@transform, "ほっかいどう", nil)
      assert result == "hokkaidou" or result == "hokkaido"

      # おちゃ → ochiya (expected: ocha) - FIXED with palatalization
      assert ExkPasswd.Transform.apply(@transform, "おちゃ", nil) == "ocha"

      # きょうと → kiyouto (expected: kyoto) - FIXED with palatalization
      result = ExkPasswd.Transform.apply(@transform, "きょうと", nil)
      assert result == "kyouto" or result == "kyoto"
    end

    test "converts complex words with multiple features" do
      assert ExkPasswd.Transform.apply(@transform, "しゃしん", nil) == "shashin"
      assert ExkPasswd.Transform.apply(@transform, "りょうり", nil) == "ryouri"
      assert ExkPasswd.Transform.apply(@transform, "ちゅうごく", nil) == "chuugoku"
    end

    test "additional edge cases for Modified Hepburn compliance" do
      # Cities with long vowels
      assert ExkPasswd.Transform.apply(@transform, "おおさか", nil) == "oosaka"
      assert ExkPasswd.Transform.apply(@transform, "なごや", nil) == "nagoya"

      # Words with multiple special features combined
      # sokuon + long vowel
      assert ExkPasswd.Transform.apply(@transform, "がっこう", nil) == "gakkou"
      # palatalization + sokuon + long vowel
      assert ExkPasswd.Transform.apply(@transform, "しょうがっこう", nil) == "shougakkou"

      # More ん before labials examples (already in n before labials test)
      # Particle は and を (typically not in passwords, but for completeness)
      # Note: Our implementation doesn't distinguish particles from regular usage
      # This is acceptable for password generation
      assert ExkPasswd.Transform.apply(@transform, "わたしは", nil) == "watashiha"
      assert ExkPasswd.Transform.apply(@transform, "これを", nil) == "korewo"
    end

    test "stress test: very long compound words" do
      # Long words combining multiple Hepburn rules
      # elementary school teacher
      long_word = "しょうがっこうのせんせい"
      result = ExkPasswd.Transform.apply(@transform, long_word, nil)
      assert result == "shougakkounosensei"

      # Katakana loanwords with long vowel marker ー
      # Note: ー is currently skipped (line 378-380 in romaji.ex)
      # コンピューター → kompyuta (ー markers skipped for password clarity)
      result = ExkPasswd.Transform.apply(@transform, "コンピューター", nil)
      assert result == "kompyuta", "Expected 'kompyuta' but got '#{result}'"
    end
  end

  describe "mixed hiragana and katakana" do
    test "handles mixed scripts" do
      assert ExkPasswd.Transform.apply(@transform, "さくらサクラ", nil) == "sakurasakura"
    end
  end

  describe "edge cases" do
    test "handles empty string" do
      assert ExkPasswd.Transform.apply(@transform, "", nil) == ""
    end

    test "handles single character" do
      assert ExkPasswd.Transform.apply(@transform, "あ", nil) == "a"
    end

    test "passes through non-Japanese characters unchanged" do
      assert ExkPasswd.Transform.apply(@transform, "hello", nil) == "hello"
      assert ExkPasswd.Transform.apply(@transform, "123", nil) == "123"
    end

    test "handles mixed Japanese and ASCII" do
      assert ExkPasswd.Transform.apply(@transform, "さくら123", nil) == "sakura123"
    end
  end

  describe "entropy contribution" do
    test "returns 0 entropy (deterministic transformation)" do
      assert ExkPasswd.Transform.entropy_bits(@transform, nil) == 0.0
    end
  end

  describe "comprehensive regression test suite" do
    # This is a large test covering many combinations to prevent regressions

    @test_cases %{
      # Basic mora
      "あ" => "a",
      "い" => "i",
      "う" => "u",
      "え" => "e",
      "お" => "o",
      "か" => "ka",
      "き" => "ki",
      "く" => "ku",
      "け" => "ke",
      "こ" => "ko",
      "さ" => "sa",
      "し" => "shi",
      "す" => "su",
      "せ" => "se",
      "そ" => "so",
      "た" => "ta",
      "ち" => "chi",
      "つ" => "tsu",
      "て" => "te",
      "と" => "to",
      "な" => "na",
      "に" => "ni",
      "ぬ" => "nu",
      "ね" => "ne",
      "の" => "no",
      "は" => "ha",
      "ひ" => "hi",
      "ふ" => "fu",
      "へ" => "he",
      "ほ" => "ho",
      "ま" => "ma",
      "み" => "mi",
      "む" => "mu",
      "め" => "me",
      "も" => "mo",
      "や" => "ya",
      "ゆ" => "yu",
      "よ" => "yo",
      "ら" => "ra",
      "り" => "ri",
      "る" => "ru",
      "れ" => "re",
      "ろ" => "ro",
      "わ" => "wa",
      "を" => "wo",
      "ん" => "n",

      # Palatalization
      "きゃ" => "kya",
      "きゅ" => "kyu",
      "きょ" => "kyo",
      "ぎゃ" => "gya",
      "ぎゅ" => "gyu",
      "ぎょ" => "gyo",
      "しゃ" => "sha",
      "しゅ" => "shu",
      "しょ" => "sho",
      "じゃ" => "ja",
      "じゅ" => "ju",
      "じょ" => "jo",
      "ちゃ" => "cha",
      "ちゅ" => "chu",
      "ちょ" => "cho",
      "にゃ" => "nya",
      "にゅ" => "nyu",
      "にょ" => "nyo",
      "ひゃ" => "hya",
      "ひゅ" => "hyu",
      "ひょ" => "hyo",
      "びゃ" => "bya",
      "びゅ" => "byu",
      "びょ" => "byo",
      "ぴゃ" => "pya",
      "ぴゅ" => "pyu",
      "ぴょ" => "pyo",
      "みゃ" => "mya",
      "みゅ" => "myu",
      "みょ" => "myo",
      "りゃ" => "rya",
      "りゅ" => "ryu",
      "りょ" => "ryo",

      # Real words
      "さくら" => "sakura",
      "にほん" => "nihon",
      "とうきょう" => "toukyou",
      "おおさか" => "oosaka",
      "なごや" => "nagoya",
      "ふじさん" => "fujisan",
      "せんせい" => "sensei",
      "がくせい" => "gakusei"
    }

    test "regression test for all basic cases" do
      Enum.each(@test_cases, fn {input, expected} ->
        result = ExkPasswd.Transform.apply(@transform, input, nil)

        assert result == expected,
               "Failed: #{input} → #{result} (expected: #{expected})"
      end)
    end
  end
end
