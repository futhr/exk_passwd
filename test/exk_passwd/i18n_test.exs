defmodule ExkPasswd.I18nTest do
  use ExUnit.Case, async: true

  alias ExkPasswd.{Config, Dictionary}

  doctest ExkPasswd.Transform.Pinyin
  doctest ExkPasswd.Transform.Romaji

  describe "word_length_bounds configuration" do
    test "allows Chinese word lengths (1-4 characters) with custom bounds" do
      chinese_words = ["中", "国", "世界", "你好"]
      Dictionary.load_custom(:chinese_test, chinese_words)

      {:ok, config} =
        Config.new(
          dictionary: :chinese_test,
          word_length: 2..2,
          word_length_bounds: 1..4
        )

      assert config.word_length == 2..2
      assert config.word_length_bounds == 1..4
    end

    test "rejects out-of-bounds word lengths" do
      {:error, msg} =
        Config.new(
          word_length: 2..3,
          word_length_bounds: 4..8
        )

      assert msg =~ "word_length range 2..3 exceeds custom bounds 4..8"
    end

    test "enforces English default bounds (4-10) when no custom bounds" do
      {:error, msg} = Config.new(word_length: 2..3)
      assert msg =~ "word_length range must be between 4 and 10"
      assert msg =~ "For non-Latin scripts"
    end

    test "allows word_length 1-50 with appropriate bounds" do
      {:ok, config} =
        Config.new(
          word_length: 1..20,
          word_length_bounds: 1..50
        )

      assert config.word_length == 1..20
    end

    test "rejects word_length minimum < 1" do
      {:error, msg} = Config.new(word_length: 0..5, word_length_bounds: 0..10)
      assert msg =~ "word_length minimum must be at least 1"
    end

    test "rejects word_length maximum > 50" do
      {:error, msg} = Config.new(word_length: 4..100, word_length_bounds: 1..100)
      assert msg =~ "word_length maximum must be at most 50"
    end
  end

  describe "Pinyin transform" do
    setup do
      chinese_words = ["中国", "世界", "你好", "朋友"]
      Dictionary.load_custom(:chinese_pinyin_test, chinese_words)
      :ok
    end

    test "converts Chinese characters to Pinyin" do
      transform = %ExkPasswd.Transform.Pinyin{}
      assert ExkPasswd.Transform.apply(transform, "中国", nil) == "zhongguo"
      assert ExkPasswd.Transform.apply(transform, "世界", nil) == "shijie"
      assert ExkPasswd.Transform.apply(transform, "你好", nil) == "nihao"
    end

    test "leaves unknown characters unchanged" do
      transform = %ExkPasswd.Transform.Pinyin{}
      # Character not in mapping
      result = ExkPasswd.Transform.apply(transform, "中xyz国", nil)
      assert result == "zhongxyzguo"
    end

    test "generates Chinese passwords with Pinyin output" do
      config =
        Config.new!(
          dictionary: :chinese_pinyin_test,
          word_length: 2..2,
          word_length_bounds: 1..4,
          num_words: 2,
          separator: "-",
          digits: {0, 0},
          padding: %{char: "", before: 0, after: 0, to_length: 0},
          case_transform: :none,
          meta: %{transforms: [%ExkPasswd.Transform.Pinyin{}]}
        )

      password = ExkPasswd.generate(config)

      # Should be ASCII only
      assert password =~ ~r/^[a-z-]+$/
      # Should contain separator
      assert String.contains?(password, "-")
    end

    test "Pinyin transform contributes no entropy" do
      transform = %ExkPasswd.Transform.Pinyin{}
      assert ExkPasswd.Transform.entropy_bits(transform, nil) == 0.0
    end
  end

  describe "Romaji transform" do
    setup do
      japanese_words = ["さくら", "やま", "うみ", "そら"]
      Dictionary.load_custom(:japanese_romaji_test, japanese_words)
      :ok
    end

    test "converts Hiragana to Romaji" do
      transform = %ExkPasswd.Transform.Romaji{}
      assert ExkPasswd.Transform.apply(transform, "さくら", nil) == "sakura"
      assert ExkPasswd.Transform.apply(transform, "やま", nil) == "yama"
      assert ExkPasswd.Transform.apply(transform, "うみ", nil) == "umi"
    end

    test "converts Katakana to Romaji" do
      transform = %ExkPasswd.Transform.Romaji{}
      assert ExkPasswd.Transform.apply(transform, "サクラ", nil) == "sakura"
      assert ExkPasswd.Transform.apply(transform, "ヤマ", nil) == "yama"
    end

    test "leaves unknown characters unchanged" do
      transform = %ExkPasswd.Transform.Romaji{}
      result = ExkPasswd.Transform.apply(transform, "さ123くら", nil)
      assert result == "sa123kura"
    end

    test "generates Japanese passwords with Romaji output" do
      config =
        Config.new!(
          dictionary: :japanese_romaji_test,
          word_length: 2..4,
          word_length_bounds: 1..10,
          num_words: 2,
          separator: "-",
          digits: {0, 0},
          padding: %{char: "", before: 0, after: 0, to_length: 0},
          case_transform: :none,
          meta: %{transforms: [%ExkPasswd.Transform.Romaji{}]}
        )

      password = ExkPasswd.generate(config)

      # Should be ASCII only
      assert password =~ ~r/^[a-z-]+$/
      # Should contain separator
      assert String.contains?(password, "-")
    end

    test "Romaji transform contributes no entropy" do
      transform = %ExkPasswd.Transform.Romaji{}
      assert ExkPasswd.Transform.entropy_bits(transform, nil) == 0.0
    end
  end

  describe "i18n password generation end-to-end" do
    test "Chinese password is memorable and compatible" do
      chinese_words = ["春天", "夏天", "秋天", "冬天"]
      Dictionary.load_custom(:chinese_e2e, chinese_words)

      config =
        Config.new!(
          dictionary: :chinese_e2e,
          word_length: 2..2,
          word_length_bounds: 1..4,
          num_words: 3,
          separator: "-",
          digits: {2, 2},
          padding: %{char: "", before: 0, after: 0, to_length: 0},
          case_transform: :none,
          meta: %{transforms: [%ExkPasswd.Transform.Pinyin{}]}
        )

      passwords = for _ <- 1..10, do: ExkPasswd.generate(config)

      # All should be ASCII (alphanumeric + separator)
      assert Enum.all?(passwords, fn pw -> pw =~ ~r/^[a-z0-9-]+$/ end)
      # All should be unique (reasonable expectation with 4 words, 3 picks)
      assert length(Enum.uniq(passwords)) >= 8
      # All should contain numbers
      assert Enum.all?(passwords, fn pw -> pw =~ ~r/\d/ end)
    end

    test "Japanese password with mixed scripts" do
      mixed_words = ["さくら", "サクラ", "うみ", "ウミ"]
      Dictionary.load_custom(:japanese_mixed_e2e, mixed_words)

      config =
        Config.new!(
          dictionary: :japanese_mixed_e2e,
          word_length: 2..3,
          word_length_bounds: 1..10,
          num_words: 2,
          separator: "-",
          digits: {2, 2},
          padding: %{char: "", before: 0, after: 0, to_length: 0},
          case_transform: :none,
          meta: %{transforms: [%ExkPasswd.Transform.Romaji{}]}
        )

      password = ExkPasswd.generate(config)

      # Both Hiragana and Katakana should convert to same Romaji
      # Format: DD-word-word-DD (digits-word-word-digits)
      assert password =~ ~r/^[0-9]+-[a-z]+-[a-z]+-[0-9]+$/
    end
  end

  describe "custom dictionary with various word lengths" do
    test "supports very short words (1-2 chars) for logographic scripts" do
      # Chinese characters often represent complete words in 1-2 chars
      short_words = ["中", "国", "爱", "好", "大", "小"]
      Dictionary.load_custom(:short_words, short_words)

      config =
        Config.new!(
          dictionary: :short_words,
          word_length: 1..2,
          word_length_bounds: 1..10,
          num_words: 4
        )

      password = ExkPasswd.generate(config)
      assert is_binary(password)
      assert String.length(password) > 0
    end

    test "supports long German compound words" do
      # German loves its compound words
      german_words = [
        "Geschwindigkeit",
        # Speed (14 chars)
        "Verantwortung",
        # Responsibility (13 chars)
        "Zusammenarbeit",
        # Cooperation (14 chars)
        "Krankenhaus"
        # Hospital (11 chars)
      ]

      Dictionary.load_custom(:german, german_words)

      config =
        Config.new!(
          dictionary: :german,
          word_length: 11..14,
          word_length_bounds: 1..50,
          num_words: 2
        )

      password = ExkPasswd.generate(config)
      assert is_binary(password)
      assert String.length(password) > 20
    end
  end

  describe "entropy calculation with i18n" do
    test "generates passwords with custom dictionary" do
      # Simpler test - just ensure it works with custom dictionaries
      chinese_words = ["字一", "字二", "字三", "字四", "字五"]
      Dictionary.load_custom(:chinese_entropy, chinese_words)

      config =
        Config.new!(
          dictionary: :chinese_entropy,
          word_length: 2..2,
          word_length_bounds: 1..10,
          num_words: 3,
          digits: {0, 0},
          padding: %{char: "", before: 0, after: 0, to_length: 0}
        )

      password = ExkPasswd.generate(config)

      # Should generate a valid password
      assert is_binary(password)
      assert String.length(password) > 0
      # Should contain Chinese characters
      assert password =~ ~r/字/
    end
  end
end
