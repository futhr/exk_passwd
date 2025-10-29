defmodule ExkPasswd do
  @moduledoc """
  ExkPasswd is a highly optimized password generation and analysis library for Elixir.

  This library provides secure, customizable password generation based on the
  XKPasswd concept - creating memorable yet strong passwords by combining
  random words with numbers, symbols, and various transformations.

  ## Quick Start

      # Generate a password with default settings
      ExkPasswd.generate()
      #=> "28?heavy?SOUND?later?94"

      # Use a preset
      ExkPasswd.generate(:xkcd)
      #=> "correct-horse-battery-staple-amazing"

      # Custom configuration using keyword list
      ExkPasswd.generate(num_words: 4, separator: "-")
      #=> "12-Happy-Forest-Dance-56"

      # Custom configuration using Config struct
      config = ExkPasswd.Config.new!(
        num_words: 4,
        separator: "-",
        case_transform: :capitalize
      )
      ExkPasswd.generate(config)
      #=> "12-Happy-Forest-Dance-56"

      # Analyze password strength
      password = ExkPasswd.generate()
      ExkPasswd.analyze_strength(password, ExkPasswd.Config.new!())
      #=> %{rating: :good, entropy_bits: 59.2, ...}

      # Generate multiple passwords in batch
      ExkPasswd.generate_batch(100)
      #=> ["password1", "password2", ...]

  ## Features

  - **Efficient generation**: Constant-time word selection using tuple indexing
  - **Entropy calculation**: Security analysis with blind and seen entropy metrics
  - **Character substitutions**: Leetspeak-style transformations for added complexity
  - **Custom dictionaries**: Load your own word lists for any language or domain
  - **Batch generation**: Optimized for generating multiple passwords
  - **Strength analysis**: Password feedback and improvement suggestions
  - **Extensibility**: Transform protocol for custom password transformations
  - **Zero dependencies**: Only uses Elixir stdlib and `:crypto`

  ## Performance

  - **Tuple-based lookups**: Constant-time word selection
  - **Cached transformations**: Pre-computed case variants
  - **Buffered random generation**: Reduced syscalls for batch operations

  ## Available Presets

  - `:default` - Balanced security and memorability (~59 bits entropy)
  - `:web32` - For websites allowing up to 32 characters (~65 bits)
  - `:web16` - For websites with 16 character limit (~42 bits - ⚠️ low security)
  - `:wifi` - 63 character WPA2 keys (~85 bits)
  - `:apple_id` - Meets Apple ID requirements (~55 bits)
  - `:security` - For security questions (~77 bits)
  - `:xkcd` - Similar to the famous XKCD comic (~65 bits)

  See `ExkPasswd.Config.Presets` for more details on each preset.

  ## Extensibility

  Custom transforms can be added using the Transform protocol.

  Example: Japanese Romaji Transform for cross-keyboard compatibility:

      defmodule MyApp.RomajiTransform do
        @moduledoc \"\"\"
        Converts Japanese hiragana/katakana to romaji for keyboard portability.

        Enables passwords created on Japanese keyboard layouts to be typed on
        English QWERTY keyboards (e.g., international travel, shared workstations).
        \"\"\"
        defstruct [:mode]

        @hiragana_to_romaji %{
          "あ" => "a", "い" => "i", "う" => "u", "さ" => "sa", "き" => "ki"
        }

        defimpl ExkPasswd.Transform do
          def apply(%{mode: _mode}, word, _config) do
            @hiragana_to_romaji
            |> Enum.reduce(word, fn {japanese, romaji}, acc ->
              String.replace(acc, japanese, romaji)
            end)
          end

          def entropy_bits(%{mode: _mode}, _config), do: 0.0
        end
      end

      # Use with Japanese dictionary
      ExkPasswd.Dictionary.load_custom(:japanese, ["さくら", "やま", "うみ"])

      config = ExkPasswd.Config.new!(
        num_words: 2,
        dictionary: :japanese,
        meta: %{
          transforms: [%MyApp.RomajiTransform{mode: :hiragana}]
        }
      )

      ExkPasswd.generate(config)
      #=> "45-sakura-yama-89"  # Typeable on any keyboard
  """

  alias ExkPasswd.{Batch, Config, Entropy, Password, Strength}

  @version Mix.Project.config()[:version]

  def version, do: @version

  @doc """
  Generate a password using default settings, a preset, keyword options, or a Config struct.

  ## Examples

      # With default settings
      ExkPasswd.generate()
      #=> "28?heavy?SOUND?later?94"

      # With a preset atom
      ExkPasswd.generate(:xkcd)
      #=> "correct-horse-battery-staple-amazing"

      # With keyword list
      ExkPasswd.generate(num_words: 4, separator: "-")
      #=> "word-word-word-word"

      # With Config struct
      config = Config.new!(num_words: 2, separator: "_")
      ExkPasswd.generate(config)
      #=> "45_HAPPY_forest_23"
  """
  @spec generate() :: String.t()
  def generate(), do: generate(:default)

  @spec generate(atom() | keyword() | Config.t()) :: String.t()
  def generate(preset) when is_atom(preset) do
    case Config.Presets.get(preset) do
      nil -> raise ArgumentError, "Unknown preset: #{inspect(preset)}"
      config -> Password.create(config)
    end
  end

  def generate(opts) when is_list(opts) do
    if Keyword.keyword?(opts) do
      Config.new!(opts) |> Password.create()
    else
      raise ArgumentError, "Expected keyword list, got: #{inspect(opts)}"
    end
  end

  def generate(%Config{} = config) do
    Password.create(config)
  end

  @doc """
  Generate a password from a preset with overrides.

  ## Examples

      # Extend preset with overrides
      ExkPasswd.generate(:xkcd, num_words: 6)
      #=> "word-word-word-word-word-word"

      ExkPasswd.generate(:default, separator: "_", num_words: 5)
      #=> "12_word_WORD_word_WORD_89"
  """
  @spec generate(atom(), keyword()) :: String.t()
  def generate(preset, overrides) when is_atom(preset) and is_list(overrides) do
    case Config.Presets.get(preset) do
      nil -> raise ArgumentError, "Unknown preset: #{inspect(preset)}"
      config -> Config.merge!(config, overrides) |> Password.create()
    end
  end

  @doc """
  Generate multiple passwords in batch with optimized performance.

  For generating 100+ passwords, this is approximately 30% faster than
  calling `generate/1` multiple times due to reduced cryptographic overhead.

  ## Parameters

  - `count` - Number of passwords to generate
  - `config` - Config to use (default: default preset)

  ## Examples

      ExkPasswd.generate_batch(10)
      #=> ["password1", "password2", ...]

      config = ExkPasswd.Config.new!(num_words: 4)
      ExkPasswd.generate_batch(5, config)
      #=> ["word-word-word-word", ...]
  """
  @spec generate_batch(pos_integer(), Config.t()) :: [String.t()]
  defdelegate generate_batch(count, config \\ Config.new!()), to: Batch

  @doc """
  Generate unique passwords in batch.

  Ensures all returned passwords are unique by regenerating duplicates.

  ## Parameters

  - `count` - Number of unique passwords
  - `config` - Config to use (default: default preset)

  ## Examples

      passwords = ExkPasswd.generate_unique_batch(10)
      length(Enum.uniq(passwords)) == 10
      #=> true
  """
  @spec generate_unique_batch(pos_integer(), Config.t()) :: [String.t()]
  defdelegate generate_unique_batch(count, config \\ Config.new!()), to: Batch

  @doc """
  Generate passwords in parallel using multiple processes.

  Best for very large batches (1000+) on multi-core systems.

  ## Parameters

  - `count` - Number of passwords
  - `config` - Config to use (default: default preset)

  ## Examples

      ExkPasswd.generate_parallel(1000)
      #=> [... 1000 passwords ...]
  """
  @spec generate_parallel(pos_integer(), Config.t()) :: [String.t()]
  defdelegate generate_parallel(count, config \\ Config.new!()), to: Batch

  @doc """
  Calculate entropy metrics for a password and config.

  Returns detailed entropy analysis including both blind entropy (brute force)
  and seen entropy (attacker knows dictionary/config).

  ## Parameters

  - `password` - The password to analyze
  - `config` - Config used to generate it

  ## Examples

      password = ExkPasswd.generate()
      config = ExkPasswd.Config.new!()
      ExkPasswd.calculate_entropy(password, config)
      #=> %{blind: 49.2, seen: 59.1, status: :good, ...}
  """
  @spec calculate_entropy(String.t(), Config.t()) :: map()
  defdelegate calculate_entropy(password, config), to: Entropy, as: :calculate

  @doc """
  Analyze password strength with user-friendly feedback.

  Returns a comprehensive report including rating, score, crack time estimates,
  and improvement suggestions.

  ## Parameters

  - `password` - Password to analyze
  - `config` - Config used to generate it

  ## Examples

      password = ExkPasswd.generate()
      config = ExkPasswd.Config.new!()
      ExkPasswd.analyze_strength(password, config)
      #=> %{rating: :good, score: 59, entropy_bits: 59.2, suggestions: [...], ...}
  """
  @spec analyze_strength(String.t(), Config.t()) :: map()
  defdelegate analyze_strength(password, config), to: Strength, as: :analyze

  @doc """
  Quick strength rating check.

  Returns just the rating without full analysis.

  ## Parameters

  - `password` - Password to check
  - `config` - Config used

  ## Returns

  One of: `:excellent`, `:good`, `:fair`, `:weak`

  ## Examples

      password = ExkPasswd.generate()
      config = ExkPasswd.Config.new!()
      ExkPasswd.strength_rating(password, config)
      #=> :good
  """
  @spec strength_rating(String.t(), Config.t()) :: Strength.rating()
  defdelegate strength_rating(password, config), to: Strength, as: :rating
end
