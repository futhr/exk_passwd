defmodule ExkPasswd do
  @moduledoc """
  Generates memorable passwords from cryptographically random words and tokens.

  ExkPasswd uses `:crypto.strong_rand_bytes/1`, ships with a filtered EFF Large
  Wordlist, and has no runtime dependencies outside Elixir/Erlang. Applications
  can provide their own dictionaries and transforms.

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

  - **Indexed generation**: Precomputed tuples for common EFF word ranges
  - **Entropy calculation**: Blind search-space and seen min-entropy estimates
  - **Character substitutions**: Deterministic or random per-word substitution
  - **Custom dictionaries**: Load your own word lists for any language or domain
  - **Batch generation**: Buffered and parallel generation APIs
  - **Strength analysis**: Rating, score, and entropy data
  - **Extensibility**: Transform protocol for custom password transformations
  - **Zero dependencies**: Only uses Elixir stdlib and `:crypto`

  ## Performance

  - **Tuple-based lookups**: Direct indexing for precomputed word ranges
  - **Cached transformations**: Pre-computed case variants
  - **Buffered random generation**: Reduced syscalls for batch operations

  ## Available Presets

  - `:default` - Balanced security and memorability (~59 bits entropy)
  - `:web32` - For websites allowing up to 32 characters (~65 bits)
  - `:web16` - Compatibility fallback for a 16-character limit (~37 bits)
  - `:wifi` - 63 printable ASCII characters for WPA/WPA2 passphrases (~105 bits)
  - `:apple_id` - Meets Apple ID requirements (~55 bits)
  - `:security` - For security questions (~77 bits)
  - `:xkcd` - Similar to the famous XKCD comic (~68 bits)

  See `ExkPasswd.Config.Presets` for more details on each preset.

  ## Extensibility

  Add transforms through `Config.meta`. The built-in transforms support case
  changes, substitutions, Pinyin, and Romaji. See `ExkPasswd.Transform` for a
  complete custom implementation example and its entropy contract.

      iex> config =
      ...>   ExkPasswd.Config.new!(
      ...>     meta: %{
      ...>       transforms: [
      ...>         %ExkPasswd.Transform.Substitution{map: %{"a" => "@"}, mode: :always}
      ...>       ]
      ...>     }
      ...>   )
      ...>
      ...> is_binary(ExkPasswd.generate(config))
      true
  """

  alias ExkPasswd.{Batch, Config, Entropy, Password, Strength}

  @version Mix.Project.config()[:version]

  @doc """
  Returns the current version of ExkPasswd.

  ## Examples

      iex> ExkPasswd.version() =~ ~r/^\\d+\\.\\d+\\.\\d+/
      true
  """
  @spec version() :: String.t()
  def version, do: @version

  @doc """
  Generate a password using default settings.

  This is equivalent to calling `generate(:default)`.

  ## Examples

      ExkPasswd.generate()
      #=> "28?heavy?SOUND?later?94"
  """
  @spec generate() :: String.t()
  def generate, do: generate(:default)

  @doc """
  Generate a password using a preset, keyword options, or a Config struct.

  ## Examples

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

  @spec generate(atom() | String.t() | keyword() | Config.t()) :: String.t()
  def generate(preset) when is_atom(preset) do
    case Config.Presets.get(preset) do
      nil -> raise ArgumentError, "Unknown preset: #{inspect(preset)}"
      config -> Password.create(config)
    end
  end

  def generate(preset) when is_binary(preset) do
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
  @spec generate(atom() | String.t(), keyword()) :: String.t()
  def generate(preset, overrides)
      when (is_atom(preset) or is_binary(preset)) and is_list(overrides) do
    case Config.Presets.get(preset) do
      nil -> raise ArgumentError, "Unknown preset: #{inspect(preset)}"
      config -> Config.merge!(config, overrides) |> Password.create()
    end
  end

  @doc """
  Generate multiple passwords with buffered random bytes.

  Buffering reduces calls to the cryptographic random source. Throughput varies
  by batch size, runtime, and hardware; benchmark both paths for the target
  environment.

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
  @spec generate_batch(non_neg_integer(), Config.t()) :: [String.t()]
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
  @spec generate_unique_batch(non_neg_integer(), Config.t()) :: [String.t()]
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
  @spec generate_parallel(non_neg_integer(), Config.t()) :: [String.t()]
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

  Returns a map with rating, score, and entropy bits.

  ## Parameters

  - `password` - Password to analyze
  - `config` - Config used to generate it

  ## Examples

      password = ExkPasswd.generate()
      config = ExkPasswd.Config.new!()
      ExkPasswd.analyze_strength(password, config)
      #=> %{rating: :good, score: 59, entropy_bits: 59.2}
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
