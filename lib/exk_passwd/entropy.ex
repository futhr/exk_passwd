defmodule ExkPasswd.Entropy do
  @moduledoc """
  Password entropy calculation and strength analysis.

  This module provides entropy metrics to assess password strength
  from two perspectives:

  - **Blind estimate**: A heuristic brute-force search-space estimate based on
    the character classes present and the password length. It is not a claim
    about the probability distribution of an observed password.

  - **Seen entropy**: A conservative min-entropy estimate when the attacker
    knows the dictionary and configuration. Deterministic case, substitution,
    Pinyin, and Romaji collisions are included.

  ## Security Model

  Password strength comes from **entropy** (number of possible combinations)
  and **cryptographically secure randomness**, not from keeping the generation
  method secret.

  ## Project Ratings

  ExkPasswd uses these project-defined bands for its convenience rating:

  - **< 40 bits**: Weak - DO NOT USE (crackable in minutes/hours)
  - **40-52 bits**: Fair - Minimal acceptable (crackable in days/months)
  - **52-78 bits**: Good - Recommended for most uses (years to centuries)
  - **78+ bits**: Excellent - High security (millennia+)

  ## Examples

      iex> config = ExkPasswd.Config.new!(num_words: 3)
      ...> password = ExkPasswd.generate(config)
      ...> result = ExkPasswd.Entropy.calculate(password, config)
      ...> result.blind > 40
      true
      iex> result.seen > 50
      true

      iex> ExkPasswd.Entropy.calculate_seen(ExkPasswd.Config.new!(num_words: 6))
      ...> # Returns entropy in bits (float)
  """

  alias ExkPasswd.{Config, Dictionary, Transform}
  alias ExkPasswd.Transform.{CaseTransform, Pinyin, Romaji, Substitution}

  @type entropy_result :: %{
          blind: float(),
          seen: float(),
          status: :excellent | :good | :fair | :weak,
          blind_crack_time: String.t(),
          seen_crack_time: String.t(),
          details: map()
        }

  # Standard thresholds in bits
  @entropy_min_excellent 78
  @entropy_min_good 52
  @entropy_min_fair 40

  # Crack time estimation: billion guesses per second (modern GPU)
  @guesses_per_second 1_000_000_000

  @doc """
  Calculate blind and seen entropy metrics for a password and settings.

  Returns detailed entropy analysis including both blind and seen entropy,
  strength status, crack time estimates, and breakdown of entropy sources.

  ## Parameters

  - `password` - The generated password string
  - `config` - The Config struct used to generate the password

  ## Returns

  A map containing:
  - `:blind` - Blind entropy in bits (float)
  - `:seen` - Seen entropy in bits (float)
  - `:status` - Overall strength (`:excellent`, `:good`, `:fair`, `:weak`)
  - `:blind_crack_time` - Human-readable crack time estimate for blind attack
  - `:seen_crack_time` - Human-readable crack time estimate for seen attack
  - `:details` - Breakdown of entropy components

  ## Examples

      iex> config = ExkPasswd.Config.new!(num_words: 4)
      ...> password = "12-HAPPY-forest-DANCE-bird-56"
      ...> result = ExkPasswd.Entropy.calculate(password, config)
      ...> is_float(result.blind) and is_float(result.seen)
      true
  """
  @spec calculate(String.t(), Config.t()) :: entropy_result()
  def calculate(password, settings) do
    settings = Config.validate!(settings)
    blind = calculate_blind(password)
    seen_result = calculate_seen_detailed(settings)
    seen = seen_result.total

    %{
      blind: blind,
      seen: seen,
      status: determine_status(blind, seen),
      blind_crack_time: estimate_crack_time(blind),
      seen_crack_time: estimate_crack_time(seen),
      details: seen_result
    }
  end

  @doc """
  Calculate a blind brute-force search-space estimate for a password string.

  Analyzes the actual password to determine alphabet size (character types used)
  and calculates entropy based on brute-force attack assumptions.

  Formula: `L × log₂(A)`
  - A = alphabet size (number of unique character types)
  - L = password length

  ## Parameters

  - `password` - The password string to analyze

  ## Returns

  Entropy in bits (float)

  ## Examples

      iex> ExkPasswd.Entropy.calculate_blind("aB3!")
      ...> # ~26.3 bits for 4-char with mixed types

      iex> blind = ExkPasswd.Entropy.calculate_blind("correcthorsebatterystaple")
      ...> blind > 100
      true
  """
  @spec calculate_blind(String.t()) :: float()
  def calculate_blind(password) do
    alphabet_size = detect_alphabet_size(password)
    length = String.length(password)

    if length == 0 do
      0.0
    else
      length * :math.log2(alphabet_size)
    end
  end

  @doc """
  Calculate seen entropy from settings.

  Calculates conservative min-entropy assuming the attacker knows the
  dictionary and configuration. Random custom transforms whose output
  distribution cannot be verified are credited with no entropy.

  ## Parameters

  - `config` - The Config struct

  ## Returns

  Entropy in bits (float)

  ## Examples

      iex> config = ExkPasswd.Config.new!(num_words: 3)
      ...> seen = ExkPasswd.Entropy.calculate_seen(config)
      ...> seen > 40
      true
  """
  @spec calculate_seen(Config.t()) :: float()
  def calculate_seen(settings) do
    calculate_seen_detailed(settings).total
  end

  @doc """
  Calculate seen entropy with detailed breakdown of entropy sources.

  Returns a map showing how each component contributes to total entropy.

  ## Parameters

  - `config` - The Config struct

  ## Returns

  Map with entropy breakdown and total

  ## Examples

      iex> config = ExkPasswd.Config.new!(num_words: 3)
      ...> result = ExkPasswd.Entropy.calculate_seen_detailed(config)
      ...> is_float(result.total)
      true
  """
  @spec calculate_seen_detailed(Config.t()) :: map()
  def calculate_seen_detailed(settings) do
    settings = Config.validate!(settings)
    word_details = calculate_word_entropy(settings)
    word_entropy = word_details.word
    separator_entropy = calculate_separator_entropy(settings)
    padding_entropy = calculate_padding_entropy(settings)
    digit_entropy = calculate_digit_entropy(settings)
    case_entropy = word_details.case
    substitution_entropy = word_details.substitution
    transform_entropy = word_details.transform

    total =
      [
        word_entropy,
        separator_entropy,
        padding_entropy,
        digit_entropy,
        case_entropy,
        substitution_entropy,
        transform_entropy
      ]
      |> Enum.sum()

    %{
      total: total,
      word_entropy: word_entropy,
      separator_entropy: separator_entropy,
      padding_entropy: padding_entropy,
      digit_entropy: digit_entropy,
      case_entropy: case_entropy,
      substitution_entropy: substitution_entropy,
      transform_entropy: transform_entropy
    }
  end

  @doc """
  Calculate effective entropy from blind and seen values.

  Uses the lower of the two as the limiting factor for security assessment.

  ## Parameters

  - `blind` - Blind entropy in bits
  - `seen` - Seen entropy in bits

  ## Returns

  Effective entropy in bits (float)

  ## Examples

      iex> ExkPasswd.Entropy.effective_entropy(80.0, 65.0)
      65.0

      iex> ExkPasswd.Entropy.effective_entropy(50.0, 70.0)
      50.0
  """
  @spec effective_entropy(float(), float()) :: float()
  def effective_entropy(blind, seen), do: min(blind, seen)

  @doc """
  Determine strength status based on entropy values.

  ## Parameters

  - `blind` - Blind entropy in bits
  - `seen` - Seen entropy in bits

  ## Returns

  Status atom: `:excellent`, `:good`, `:fair`, or `:weak`

  ## Examples

      iex> ExkPasswd.Entropy.determine_status(80, 80)
      :excellent

      iex> ExkPasswd.Entropy.determine_status(60, 55)
      :good
  """
  @spec determine_status(float(), float()) :: :excellent | :good | :fair | :weak
  def determine_status(blind, seen) do
    eff = effective_entropy(blind, seen)

    cond do
      eff >= @entropy_min_excellent -> :excellent
      eff >= @entropy_min_good -> :good
      eff >= @entropy_min_fair -> :fair
      true -> :weak
    end
  end

  @doc """
  Estimate time to crack password based on entropy.

  Assumes 1 billion guesses per second (modern GPU capability).

  ## Parameters

  - `entropy_bits` - Entropy in bits

  ## Returns

  Human-readable time estimate string

  ## Examples

      iex> time = ExkPasswd.Entropy.estimate_crack_time(40)
      ...> String.contains?(time, "minute") or String.contains?(time, "second")
      true

      iex> time = ExkPasswd.Entropy.estimate_crack_time(80)
      ...> String.contains?(time, "year") or String.contains?(time, "centur")
      true
  """
  @spec estimate_crack_time(float()) :: String.t()
  def estimate_crack_time(entropy_bits) when entropy_bits >= 100, do: "billions of years"

  def estimate_crack_time(entropy_bits) do
    # This is a deliberately simple comparison model, not a prediction for a
    # particular password hash or an online service with rate limiting.
    total_combinations = :math.pow(2, entropy_bits)

    # Average time to crack (assuming found at 50% of search space)
    seconds = total_combinations / (2 * @guesses_per_second)

    format_time(seconds)
  end

  # Character class sizes for alphabet detection
  @lowercase_size 26
  @uppercase_size 26
  @digits_size 10
  @symbols_size 33

  defp detect_alphabet_size(password) do
    graphemes = String.graphemes(password)

    has_lowercase = Enum.any?(graphemes, &(&1 =~ ~r/[a-z]/))
    has_uppercase = Enum.any?(graphemes, &(&1 =~ ~r/[A-Z]/))
    has_digits = Enum.any?(graphemes, &(&1 =~ ~r/[0-9]/))
    has_symbols = Enum.any?(graphemes, &(&1 =~ ~r/[^a-zA-Z0-9]/))

    [
      {has_lowercase, @lowercase_size},
      {has_uppercase, @uppercase_size},
      {has_digits, @digits_size},
      {has_symbols, @symbols_size}
    ]
    |> Enum.filter(fn {present?, _} -> present? end)
    |> Enum.reduce(0, fn {_, size}, acc -> acc + size end)
    |> max(1)
  end

  defp calculate_word_entropy(config) do
    base_entropy =
      config
      |> dictionary_words(:none)
      |> uniform_distribution()
      |> distribution_entropy()

    0..(config.num_words - 1)
    |> Enum.map(&word_entropy_for_position(config, &1, base_entropy))
    |> Enum.reduce(%{word: 0.0, case: 0.0, substitution: 0.0, transform: 0.0}, fn item, acc ->
      Map.merge(acc, item, fn _, left, right -> left + right end)
    end)
  end

  defp calculate_separator_entropy(config) do
    separator_chars = String.graphemes(config.separator)
    char_count = length(separator_chars)

    if char_count <= 1 do
      0.0
    else
      # One separator choice for the entire password
      :math.log2(char_count)
    end
  end

  defp calculate_padding_entropy(config) do
    padding_chars = String.graphemes(config.padding.char)
    char_count = length(padding_chars)

    if char_count > 0 and config.padding.to_length == 0 and
         (config.padding.before > 0 or config.padding.after > 0) do
      :math.log2(char_count)
    else
      0.0
    end
  end

  defp calculate_digit_entropy(config) do
    {digits_before, digits_after} = config.digits
    digit_entropy(digits_before) + digit_entropy(digits_after)
  end

  defp digit_entropy(0), do: 0.0
  defp digit_entropy(n), do: n * :math.log2(10)

  defp word_entropy_for_position(config, position, base_entropy) do
    case_distribution = case_distribution(config, position)
    case_entropy = distribution_entropy(case_distribution)
    substitution_distribution = apply_configured_substitution(case_distribution, config)
    substitution_entropy = distribution_entropy(substitution_distribution)

    final_entropy =
      case apply_meta_transforms(substitution_distribution, config) do
        {:ok, distribution} -> distribution_entropy(distribution)
        :unknown_random_transform -> 0.0
      end

    allocate_word_entropy(base_entropy, case_entropy, substitution_entropy, final_entropy)
  end

  defp allocate_word_entropy(base, after_case, after_substitution, final) do
    word = min(base, final)
    remaining = max(final - word, 0.0)
    case_part = min(max(after_case - base, 0.0), remaining)
    remaining = remaining - case_part
    substitution = min(max(after_substitution - after_case, 0.0), remaining)

    %{
      word: word,
      case: case_part,
      substitution: substitution,
      transform: max(remaining - substitution, 0.0)
    }
  end

  defp case_distribution(%{case_transform: :random} = config, _) do
    mix_distributions(
      config |> dictionary_words(:lower) |> uniform_distribution(),
      config |> dictionary_words(:upper) |> uniform_distribution()
    )
  end

  defp case_distribution(%{case_transform: :alternate} = config, position) do
    variant = if rem(position, 2) == 0, do: :lower, else: :upper
    config |> dictionary_words(variant) |> uniform_distribution()
  end

  defp case_distribution(%{case_transform: :invert} = config, _) do
    config
    |> dictionary_words(:none)
    |> uniform_distribution()
    |> map_distribution(&invert_case/1)
  end

  defp case_distribution(config, _) do
    config |> dictionary_words(config.case_transform) |> uniform_distribution()
  end

  defp dictionary_words(config, variant) do
    Dictionary.words_between(
      config.word_length.first,
      config.word_length.last,
      variant,
      config.dictionary
    )
  end

  defp apply_configured_substitution(distribution, %{substitution_mode: :none}),
    do: distribution

  defp apply_configured_substitution(distribution, %{substitutions: substitutions})
       when map_size(substitutions) == 0,
       do: distribution

  defp apply_configured_substitution(distribution, config) do
    transform = %Substitution{map: config.substitutions, mode: config.substitution_mode}
    transform_distribution(distribution, transform, config)
  end

  defp apply_meta_transforms(distribution, config) do
    config
    |> Config.get_meta(:transforms, [])
    |> Enum.reduce_while({:ok, distribution}, fn transform, {:ok, current} ->
      case transform_distribution(current, transform, config) do
        :unknown_random_transform -> {:halt, :unknown_random_transform}
        transformed -> {:cont, {:ok, transformed}}
      end
    end)
  end

  defp transform_distribution(distribution, %Substitution{mode: :none}, _), do: distribution

  defp transform_distribution(distribution, %Substitution{mode: :always} = transform, config) do
    map_distribution(distribution, &Transform.apply(transform, &1, config))
  end

  defp transform_distribution(distribution, %Substitution{mode: :random} = transform, config) do
    applied = %{transform | mode: :always}
    random_map_distribution(distribution, & &1, &Transform.apply(applied, &1, config))
  end

  defp transform_distribution(distribution, %CaseTransform{mode: :random} = transform, config) do
    lower = %{transform | mode: :lower}
    upper = %{transform | mode: :upper}

    random_map_distribution(
      distribution,
      &Transform.apply(lower, &1, config),
      &Transform.apply(upper, &1, config)
    )
  end

  defp transform_distribution(distribution, %CaseTransform{} = transform, config) do
    map_distribution(distribution, &Transform.apply(transform, &1, config))
  end

  defp transform_distribution(distribution, transform, config)
       when is_struct(transform, Pinyin) or is_struct(transform, Romaji) do
    map_distribution(distribution, &Transform.apply(transform, &1, config))
  end

  defp transform_distribution(distribution, transform, config) do
    if Transform.entropy_bits(transform, config) == 0.0 do
      map_distribution(distribution, &Transform.apply(transform, &1, config))
    else
      :unknown_random_transform
    end
  end

  defp uniform_distribution([]), do: %{}

  defp uniform_distribution(words) do
    probability = 1.0 / length(words)
    Map.new(words, &{&1, probability})
  end

  defp map_distribution(distribution, mapper) do
    Enum.reduce(distribution, %{}, fn {word, probability}, acc ->
      Map.update(acc, mapper.(word), probability, &(&1 + probability))
    end)
  end

  defp random_map_distribution(distribution, first_mapper, second_mapper) do
    first = distribution |> map_distribution(first_mapper) |> scale_distribution(0.5)
    second = distribution |> map_distribution(second_mapper) |> scale_distribution(0.5)
    merge_distributions(first, second)
  end

  defp mix_distributions(first, second) do
    merge_distributions(scale_distribution(first, 0.5), scale_distribution(second, 0.5))
  end

  defp scale_distribution(distribution, factor) do
    Map.new(distribution, fn {word, probability} -> {word, probability * factor} end)
  end

  defp merge_distributions(first, second) do
    Map.merge(first, second, fn _, left, right -> left + right end)
  end

  defp distribution_entropy(distribution) when map_size(distribution) == 0, do: 0.0

  defp distribution_entropy(distribution) do
    max_probability = distribution |> Map.values() |> Enum.max()
    -:math.log2(max_probability)
  end

  defp invert_case(word) do
    case String.next_codepoint(word) do
      {head, rest} -> String.downcase(head) <> String.upcase(rest)
      nil -> word
    end
  end

  defp format_time(seconds) when seconds < 1 do
    "instant"
  end

  defp format_time(seconds) when seconds < 60 do
    "#{Float.round(seconds, 1)} seconds"
  end

  defp format_time(seconds) when seconds < 3600 do
    minutes = seconds / 60
    "#{Float.round(minutes, 1)} minutes"
  end

  defp format_time(seconds) when seconds < 86400 do
    hours = seconds / 3600
    "#{Float.round(hours, 1)} hours"
  end

  defp format_time(seconds) when seconds < 31_536_000 do
    days = seconds / 86400
    "#{Float.round(days, 1)} days"
  end

  defp format_time(seconds) when seconds < 3_153_600_000 do
    years = seconds / 31_536_000
    "#{Float.round(years, 1)} years"
  end

  defp format_time(seconds) when seconds < 31_536_000_000 do
    centuries = seconds / 3_153_600_000
    "#{Float.round(centuries, 1)} centuries"
  end

  defp format_time(seconds) when seconds < 31_536_000_000_000 do
    millennia = seconds / 31_536_000_000
    "#{Float.round(millennia, 1)} millennia"
  end

  defp format_time(seconds) when seconds < 31_536_000_000_000_000 do
    millions = seconds / 31_536_000_000_000
    "#{Float.round(millions, 1)} million years"
  end

  defp format_time(_) do
    "billions of years"
  end
end
