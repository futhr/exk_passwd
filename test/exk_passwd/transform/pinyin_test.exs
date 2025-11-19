defmodule ExkPasswd.Transform.PinyinTest do
  @moduledoc """
  Comprehensive tests for Chinese Hanzi to Pinyin transformation.

  Tests cover:
  - Basic character conversion
  - ü/v keyboard compatibility (critical for IME input)
  - High-frequency character coverage
  - Edge cases and mixed text
  - Hanzi detection functions
  """
  use ExUnit.Case, async: true
  doctest ExkPasswd.Transform.Pinyin

  alias ExkPasswd.Transform.Pinyin

  @transform %Pinyin{}

  describe "basic pinyin conversion" do
    test "converts common greetings" do
      assert ExkPasswd.Transform.apply(@transform, "你好", nil) == "nihao"
      assert ExkPasswd.Transform.apply(@transform, "再见", nil) == "zaijian"
    end

    test "converts country names" do
      assert ExkPasswd.Transform.apply(@transform, "中国", nil) == "zhongguo"
      assert ExkPasswd.Transform.apply(@transform, "美国", nil) == "meiguo"
    end

    test "converts common words" do
      assert ExkPasswd.Transform.apply(@transform, "世界", nil) == "shijie"
      assert ExkPasswd.Transform.apply(@transform, "朋友", nil) == "pengyou"
      assert ExkPasswd.Transform.apply(@transform, "学生", nil) == "xuesheng"
    end

    test "converts numbers" do
      assert ExkPasswd.Transform.apply(@transform, "一二三", nil) == "yiersan"
      assert ExkPasswd.Transform.apply(@transform, "四五六", nil) == "siwuliu"
      assert ExkPasswd.Transform.apply(@transform, "七八九十", nil) == "qibajiushi"
    end

    test "converts single characters" do
      assert ExkPasswd.Transform.apply(@transform, "人", nil) == "ren"
      assert ExkPasswd.Transform.apply(@transform, "大", nil) == "da"
      assert ExkPasswd.Transform.apply(@transform, "小", nil) == "xiao"
    end
  end

  describe "ü/v keyboard compatibility" do
    test "uses v for ü after l" do
      # 绿 (green) - lǜ → lv
      assert ExkPasswd.Transform.apply(@transform, "绿", nil) == "lv"
      # 旅 (travel) - lǚ → lv (if in map)
    end

    test "uses v for ü after n" do
      # 女 (female) - nǚ → nv
      assert ExkPasswd.Transform.apply(@transform, "女", nil) == "nv"
      # 女人 - nǚrén → nvren
      assert ExkPasswd.Transform.apply(@transform, "女人", nil) == "nvren"
    end

    test "uses u for ü after j/q/x/y" do
      # After j/q/x/y, ü is written as u (no ambiguity)
      # 去 (go) - qù → qu
      assert ExkPasswd.Transform.apply(@transform, "去", nil) == "qu"
      # 学 (study) - xué → xue
      assert ExkPasswd.Transform.apply(@transform, "学", nil) == "xue"
      # 雨 (rain) - yǔ → yu
      assert ExkPasswd.Transform.apply(@transform, "雨", nil) == "yu"
      # 军 (army) - jūn → jun
      assert ExkPasswd.Transform.apply(@transform, "军", nil) == "jun"
    end
  end

  describe "high-frequency character coverage" do
    test "converts top 10 most frequent characters" do
      # Top 10: 的一是不了在人有我他
      assert ExkPasswd.Transform.apply(@transform, "的", nil) == "de"
      assert ExkPasswd.Transform.apply(@transform, "一", nil) == "yi"
      assert ExkPasswd.Transform.apply(@transform, "是", nil) == "shi"
      assert ExkPasswd.Transform.apply(@transform, "不", nil) == "bu"
      assert ExkPasswd.Transform.apply(@transform, "了", nil) == "le"
      assert ExkPasswd.Transform.apply(@transform, "在", nil) == "zai"
      assert ExkPasswd.Transform.apply(@transform, "人", nil) == "ren"
      assert ExkPasswd.Transform.apply(@transform, "有", nil) == "you"
      assert ExkPasswd.Transform.apply(@transform, "我", nil) == "wo"
      assert ExkPasswd.Transform.apply(@transform, "他", nil) == "ta"
    end

    test "converts pronouns" do
      assert ExkPasswd.Transform.apply(@transform, "我", nil) == "wo"
      assert ExkPasswd.Transform.apply(@transform, "你", nil) == "ni"
      assert ExkPasswd.Transform.apply(@transform, "他", nil) == "ta"
      assert ExkPasswd.Transform.apply(@transform, "她", nil) == "ta"
      assert ExkPasswd.Transform.apply(@transform, "它", nil) == "ta"
      assert ExkPasswd.Transform.apply(@transform, "们", nil) == "men"
      assert ExkPasswd.Transform.apply(@transform, "这", nil) == "zhe"
      assert ExkPasswd.Transform.apply(@transform, "那", nil) == "na"
    end

    test "converts common verbs" do
      assert ExkPasswd.Transform.apply(@transform, "说", nil) == "shuo"
      assert ExkPasswd.Transform.apply(@transform, "看", nil) == "kan"
      assert ExkPasswd.Transform.apply(@transform, "听", nil) == "ting"
      assert ExkPasswd.Transform.apply(@transform, "想", nil) == "xiang"
      assert ExkPasswd.Transform.apply(@transform, "要", nil) == "yao"
      assert ExkPasswd.Transform.apply(@transform, "能", nil) == "neng"
      assert ExkPasswd.Transform.apply(@transform, "会", nil) == "hui"
      assert ExkPasswd.Transform.apply(@transform, "去", nil) == "qu"
      assert ExkPasswd.Transform.apply(@transform, "来", nil) == "lai"
    end

    test "converts time-related words" do
      assert ExkPasswd.Transform.apply(@transform, "今", nil) == "jin"
      assert ExkPasswd.Transform.apply(@transform, "昨", nil) == "zuo"
      assert ExkPasswd.Transform.apply(@transform, "天", nil) == "tian"
      assert ExkPasswd.Transform.apply(@transform, "早", nil) == "zao"
      assert ExkPasswd.Transform.apply(@transform, "晚", nil) == "wan"
      assert ExkPasswd.Transform.apply(@transform, "年", nil) == "nian"
    end

    test "converts direction words" do
      assert ExkPasswd.Transform.apply(@transform, "东", nil) == "dong"
      assert ExkPasswd.Transform.apply(@transform, "西", nil) == "xi"
      assert ExkPasswd.Transform.apply(@transform, "南", nil) == "nan"
      assert ExkPasswd.Transform.apply(@transform, "北", nil) == "bei"
      assert ExkPasswd.Transform.apply(@transform, "上", nil) == "shang"
      assert ExkPasswd.Transform.apply(@transform, "下", nil) == "xia"
      assert ExkPasswd.Transform.apply(@transform, "左", nil) == "zuo"
      assert ExkPasswd.Transform.apply(@transform, "右", nil) == "you"
    end
  end

  describe "nature and elements" do
    test "converts nature words" do
      assert ExkPasswd.Transform.apply(@transform, "山", nil) == "shan"
      assert ExkPasswd.Transform.apply(@transform, "水", nil) == "shui"
      assert ExkPasswd.Transform.apply(@transform, "火", nil) == "huo"
      assert ExkPasswd.Transform.apply(@transform, "风", nil) == "feng"
      assert ExkPasswd.Transform.apply(@transform, "云", nil) == "yun"
      assert ExkPasswd.Transform.apply(@transform, "雨", nil) == "yu"
      assert ExkPasswd.Transform.apply(@transform, "雪", nil) == "xue"
    end

    test "converts season words" do
      assert ExkPasswd.Transform.apply(@transform, "春", nil) == "chun"
      assert ExkPasswd.Transform.apply(@transform, "夏", nil) == "xia"
      assert ExkPasswd.Transform.apply(@transform, "秋", nil) == "qiu"
      assert ExkPasswd.Transform.apply(@transform, "冬", nil) == "dong"
    end

    test "converts color words" do
      assert ExkPasswd.Transform.apply(@transform, "红", nil) == "hong"
      assert ExkPasswd.Transform.apply(@transform, "绿", nil) == "lv"
      assert ExkPasswd.Transform.apply(@transform, "蓝", nil) == "lan"
      assert ExkPasswd.Transform.apply(@transform, "黄", nil) == "huang"
      assert ExkPasswd.Transform.apply(@transform, "白", nil) == "bai"
      assert ExkPasswd.Transform.apply(@transform, "黑", nil) == "hei"
    end
  end

  describe "animals" do
    test "converts animal words" do
      assert ExkPasswd.Transform.apply(@transform, "马", nil) == "ma"
      assert ExkPasswd.Transform.apply(@transform, "牛", nil) == "niu"
      assert ExkPasswd.Transform.apply(@transform, "羊", nil) == "yang"
      assert ExkPasswd.Transform.apply(@transform, "鸟", nil) == "niao"
      assert ExkPasswd.Transform.apply(@transform, "鱼", nil) == "yu"
      assert ExkPasswd.Transform.apply(@transform, "龙", nil) == "long"
      assert ExkPasswd.Transform.apply(@transform, "虎", nil) == "hu"
    end
  end

  describe "edge cases" do
    test "handles empty string" do
      assert ExkPasswd.Transform.apply(@transform, "", nil) == ""
    end

    test "passes through ASCII text unchanged" do
      assert ExkPasswd.Transform.apply(@transform, "hello", nil) == "hello"
      assert ExkPasswd.Transform.apply(@transform, "123", nil) == "123"
      assert ExkPasswd.Transform.apply(@transform, "!@#", nil) == "!@#"
    end

    test "handles mixed Chinese and ASCII" do
      assert ExkPasswd.Transform.apply(@transform, "你好world", nil) == "nihaoworld"
      assert ExkPasswd.Transform.apply(@transform, "中国123", nil) == "zhongguo123"
      assert ExkPasswd.Transform.apply(@transform, "test中文", nil) == "testzhongwen"
    end

    test "passes through unknown characters unchanged" do
      # Characters not in the mapping should pass through
      result = ExkPasswd.Transform.apply(@transform, "中X国", nil)
      assert result == "zhongXguo"
    end

    test "handles spaces and punctuation" do
      assert ExkPasswd.Transform.apply(@transform, "你 好", nil) == "ni hao"
      assert ExkPasswd.Transform.apply(@transform, "你，好", nil) == "ni，hao"
    end
  end

  describe "compound words and phrases" do
    test "converts compound words correctly" do
      assert ExkPasswd.Transform.apply(@transform, "电脑", nil) == "diannao"
      assert ExkPasswd.Transform.apply(@transform, "手机", nil) == "shouji"
      assert ExkPasswd.Transform.apply(@transform, "大家", nil) == "dajia"
      assert ExkPasswd.Transform.apply(@transform, "小心", nil) == "xiaoxin"
    end

    test "converts common phrases" do
      assert ExkPasswd.Transform.apply(@transform, "中国人", nil) == "zhongguoren"
      assert ExkPasswd.Transform.apply(@transform, "好朋友", nil) == "haopengyou"
      assert ExkPasswd.Transform.apply(@transform, "大学生", nil) == "daxuesheng"
    end
  end

  describe "pinyin initials coverage" do
    test "covers all 21 initials" do
      # Testing one character for each initial
      # b p m f
      assert ExkPasswd.Transform.apply(@transform, "不", nil) == "bu"
      assert ExkPasswd.Transform.apply(@transform, "平", nil) == "ping"
      assert ExkPasswd.Transform.apply(@transform, "明", nil) == "ming"
      assert ExkPasswd.Transform.apply(@transform, "风", nil) == "feng"

      # d t n l
      assert ExkPasswd.Transform.apply(@transform, "大", nil) == "da"
      assert ExkPasswd.Transform.apply(@transform, "天", nil) == "tian"
      assert ExkPasswd.Transform.apply(@transform, "你", nil) == "ni"
      assert ExkPasswd.Transform.apply(@transform, "来", nil) == "lai"

      # g k h
      assert ExkPasswd.Transform.apply(@transform, "国", nil) == "guo"
      assert ExkPasswd.Transform.apply(@transform, "快", nil) == "kuai"
      assert ExkPasswd.Transform.apply(@transform, "好", nil) == "hao"

      # j q x
      assert ExkPasswd.Transform.apply(@transform, "家", nil) == "jia"
      assert ExkPasswd.Transform.apply(@transform, "去", nil) == "qu"
      assert ExkPasswd.Transform.apply(@transform, "小", nil) == "xiao"

      # zh ch sh r
      assert ExkPasswd.Transform.apply(@transform, "中", nil) == "zhong"
      assert ExkPasswd.Transform.apply(@transform, "吃", nil) == "chi"
      assert ExkPasswd.Transform.apply(@transform, "是", nil) == "shi"
      assert ExkPasswd.Transform.apply(@transform, "人", nil) == "ren"

      # z c s
      assert ExkPasswd.Transform.apply(@transform, "在", nil) == "zai"
      assert ExkPasswd.Transform.apply(@transform, "从", nil) == "cong"
      assert ExkPasswd.Transform.apply(@transform, "说", nil) == "shuo"

      # y w (semi-vowels)
      assert ExkPasswd.Transform.apply(@transform, "有", nil) == "you"
      assert ExkPasswd.Transform.apply(@transform, "我", nil) == "wo"
    end
  end

  describe "contains_hanzi?/1" do
    test "returns true for Chinese text" do
      assert Pinyin.contains_hanzi?("你好") == true
      assert Pinyin.contains_hanzi?("中国") == true
      assert Pinyin.contains_hanzi?("一") == true
    end

    test "returns false for ASCII text" do
      assert Pinyin.contains_hanzi?("hello") == false
      assert Pinyin.contains_hanzi?("123") == false
      assert Pinyin.contains_hanzi?("") == false
    end

    test "returns true for mixed text" do
      assert Pinyin.contains_hanzi?("hello中国") == true
      assert Pinyin.contains_hanzi?("123你好456") == true
      assert Pinyin.contains_hanzi?("test文test") == true
    end

    test "returns false for other scripts" do
      # Japanese hiragana/katakana are not Hanzi
      assert Pinyin.contains_hanzi?("さくら") == false
      assert Pinyin.contains_hanzi?("サクラ") == false
      # But Kanji (shared characters) are Hanzi
      assert Pinyin.contains_hanzi?("日本") == true
    end
  end

  describe "hanzi?/1" do
    test "returns true for single Hanzi characters" do
      assert Pinyin.hanzi?("中") == true
      assert Pinyin.hanzi?("国") == true
      assert Pinyin.hanzi?("人") == true
      assert Pinyin.hanzi?("一") == true
    end

    test "returns false for non-Hanzi" do
      assert Pinyin.hanzi?("a") == false
      assert Pinyin.hanzi?("1") == false
      assert Pinyin.hanzi?("!") == false
      assert Pinyin.hanzi?("") == false
    end

    test "handles CJK extension ranges" do
      # CJK Extension A character (U+3400)
      assert Pinyin.hanzi?(<<0xE3, 0x90, 0x80>>) == true
    end

    test "returns true for first character of multi-char string" do
      # hanzi? checks the first character
      assert Pinyin.hanzi?("中国") == true
    end

    test "handles edge cases gracefully" do
      # Test with characters outside typical ranges
      # Hiragana
      assert Pinyin.hanzi?("あ") == false
      # Katakana
      assert Pinyin.hanzi?("ア") == false
      # Greek
      assert Pinyin.hanzi?("α") == false
      # Korean Hangul
      assert Pinyin.hanzi?("한") == false
    end
  end

  describe "entropy contribution" do
    test "returns 0 entropy (deterministic transformation)" do
      assert ExkPasswd.Transform.entropy_bits(@transform, nil) == 0.0
    end
  end

  describe "pinyin_map/0" do
    test "returns a map" do
      map = Pinyin.pinyin_map()
      assert is_map(map)
    end

    test "contains expected mappings" do
      map = Pinyin.pinyin_map()
      assert map["中"] == "zhong"
      assert map["你"] == "ni"
      assert map["好"] == "hao"
      assert map["女"] == "nv"
      assert map["绿"] == "lv"
    end

    test "has substantial coverage" do
      map = Pinyin.pinyin_map()
      # Should have 500+ characters
      assert map_size(map) >= 500
    end
  end

  describe "real-world password scenarios" do
    test "generates typeable passwords from Chinese words" do
      # Simulating password generation with Chinese words
      words = ["中国", "世界", "你好", "朋友"]

      pinyin_words =
        Enum.map(words, fn word ->
          ExkPasswd.Transform.apply(@transform, word, nil)
        end)

      assert pinyin_words == ["zhongguo", "shijie", "nihao", "pengyou"]

      # All output should be ASCII-only (keyboard compatible)
      for word <- pinyin_words do
        assert String.match?(word, ~r/^[a-z]+$/)
      end
    end

    test "handles common Chinese password patterns" do
      # Common patterns Chinese users might use
      assert ExkPasswd.Transform.apply(@transform, "我爱你", nil) == "woaini"
      assert ExkPasswd.Transform.apply(@transform, "密码", nil) == "mima"
      assert ExkPasswd.Transform.apply(@transform, "安全", nil) == "anquan"
    end
  end

  describe "regression tests" do
    test "all lv/nv syllables use v correctly" do
      # These are the only syllables that need v for ü
      assert ExkPasswd.Transform.apply(@transform, "女", nil) == "nv"
      assert ExkPasswd.Transform.apply(@transform, "绿", nil) == "lv"
    end

    test "ju/qu/xu/yu syllables use u correctly" do
      # After j/q/x/y, ü is always written as u
      assert ExkPasswd.Transform.apply(@transform, "去", nil) == "qu"
      assert ExkPasswd.Transform.apply(@transform, "学", nil) == "xue"
      assert ExkPasswd.Transform.apply(@transform, "雨", nil) == "yu"
      assert ExkPasswd.Transform.apply(@transform, "军", nil) == "jun"
    end

    test "retroflex initials (zh ch sh r) work correctly" do
      assert ExkPasswd.Transform.apply(@transform, "中", nil) == "zhong"
      assert ExkPasswd.Transform.apply(@transform, "吃", nil) == "chi"
      assert ExkPasswd.Transform.apply(@transform, "是", nil) == "shi"
      assert ExkPasswd.Transform.apply(@transform, "日", nil) == "ri"
    end

    test "handles particles correctly" do
      assert ExkPasswd.Transform.apply(@transform, "的", nil) == "de"
      assert ExkPasswd.Transform.apply(@transform, "了", nil) == "le"
      assert ExkPasswd.Transform.apply(@transform, "着", nil) == "zhe"
      assert ExkPasswd.Transform.apply(@transform, "过", nil) == "guo"
      assert ExkPasswd.Transform.apply(@transform, "吗", nil) == "ma"
      assert ExkPasswd.Transform.apply(@transform, "呢", nil) == "ne"
    end
  end
end
