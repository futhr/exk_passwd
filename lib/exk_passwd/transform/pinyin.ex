defmodule ExkPasswd.Transform.Pinyin do
  @moduledoc """
  Converts Chinese characters to Pinyin romanization for keyboard compatibility.

  This transform enables passwords with Chinese words to be typed on any keyboard
  layout (QWERTY, AZERTY, etc.) while maintaining memorability for Chinese speakers.

  ## Use Case

  - **Dictionary**: Chinese words (memorability in native language)
  - **Transform**: Pinyin conversion (ASCII output for compatibility)
  - **Result**: Memorable for Chinese speakers, compatible with all systems

  ## Examples

      # Load Chinese dictionary
      ExkPasswd.Dictionary.load_custom(:chinese, ["中国", "世界", "你好", "朋友"])

      config = ExkPasswd.Config.new!(
        dictionary: :chinese,
        word_length: 2..4,
        word_length_bounds: 1..10,
        separator: "-",
        meta: %{
          transforms: [%ExkPasswd.Transform.Pinyin{}]
        }
      )

      ExkPasswd.generate(config)
      #=> "45-zhongguo-shijie-nihao-89"
      # Memorable: Chinese speaker remembers "中国 世界 你好"
      # Compatible: Works on any keyboard, any system

  ## Coverage

  This module includes common Chinese characters. For comprehensive coverage,
  consider using a full Pinyin library or extending the mapping.

  ## Limitations

  - Pinyin romanization is lossy (多音字 - multiple pronunciations)
  - Tone markers are omitted for simplicity (ma instead of mā/má/mǎ/mà)
  - Characters not in the mapping are left unchanged
  """

  defstruct []

  @type t :: %__MODULE__{}

  # Common Chinese characters with Pinyin romanization
  # This is a curated list of common characters for password use
  # For full coverage, consider integrating a comprehensive Pinyin library
  @pinyin_map_data %{
    # Common words
    "中" => "zhong",
    "国" => "guo",
    "世" => "shi",
    "界" => "jie",
    "你" => "ni",
    "好" => "hao",
    "朋" => "peng",
    "友" => "you",
    "爱" => "ai",
    "家" => "jia",
    "人" => "ren",
    "大" => "da",
    "小" => "xiao",
    "天" => "tian",
    "地" => "di",
    "水" => "shui",
    "火" => "huo",
    "山" => "shan",
    "海" => "hai",
    "风" => "feng",
    "云" => "yun",
    "雨" => "yu",
    "雪" => "xue",
    "花" => "hua",
    "树" => "shu",
    "月" => "yue",
    "日" => "ri",
    "星" => "xing",
    "光" => "guang",
    "明" => "ming",
    "亮" => "liang",
    "和" => "he",
    "平" => "ping",
    "安" => "an",
    "快" => "kuai",
    "乐" => "le",
    "喜" => "xi",
    "欢" => "huan",
    "美" => "mei",
    "丽" => "li",
    "长" => "chang",
    "高" => "gao",
    "新" => "xin",
    "老" => "lao",
    "东" => "dong",
    "西" => "xi",
    "南" => "nan",
    "北" => "bei",
    "春" => "chun",
    "夏" => "xia",
    "秋" => "qiu",
    "冬" => "dong",
    "书" => "shu",
    "学" => "xue",
    "生" => "sheng",
    "工" => "gong",
    "作" => "zuo",
    "时" => "shi",
    "间" => "jian",
    "年" => "nian",
    "金" => "jin",
    "木" => "mu",
    "土" => "tu",
    "心" => "xin",
    "手" => "shou",
    "足" => "zu",
    "目" => "mu",
    "耳" => "er",
    "口" => "kou",
    "力" => "li",
    "子" => "zi",
    "女" => "nv",
    "男" => "nan",
    "王" => "wang",
    "门" => "men",
    "车" => "che",
    "马" => "ma",
    "鸟" => "niao",
    "鱼" => "yu",
    "虫" => "chong",
    "石" => "shi",
    "田" => "tian",
    "白" => "bai",
    "黑" => "hei",
    "红" => "hong",
    "绿" => "lv",
    "蓝" => "lan",
    "黄" => "huang"
  }

  def pinyin_map, do: @pinyin_map_data

  defimpl ExkPasswd.Transform do
    @doc """
    Apply Pinyin romanization to a Chinese word.

    Converts each Chinese character to its Pinyin equivalent character by character.
    Characters not in the mapping are left unchanged.

    ## Parameters

    - `_transform` - The Pinyin transform struct (unused, no configuration)
    - `word` - Chinese word to convert
    - `_config` - Config struct (unused)

    ## Returns

    Romanized word in Pinyin.

    ## Examples

        iex> ExkPasswd.Transform.apply(%ExkPasswd.Transform.Pinyin{}, "中国", nil)
        "zhongguo"

        iex> ExkPasswd.Transform.apply(%ExkPasswd.Transform.Pinyin{}, "你好", nil)
        "nihao"
    """
    def apply(_transform, word, _config) do
      pinyin_map = ExkPasswd.Transform.Pinyin.pinyin_map()

      word
      |> String.graphemes()
      |> Enum.map(fn char -> Map.get(pinyin_map, char, char) end)
      |> Enum.join()
    end

    @doc """
    Returns entropy contribution of Pinyin transform.

    Pinyin conversion is deterministic (one-to-one mapping), so it contributes
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
