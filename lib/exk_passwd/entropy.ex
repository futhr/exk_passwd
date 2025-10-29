defmodule ExkPasswd.Entropy do
  @moduledoc """
  Password entropy calculation and strength analysis.

  This module provides comprehensive entropy metrics to assess password strength
  from two perspectives:

  - **Blind Entropy**: Assumes attacker uses brute force with no knowledge of
    how the password was generated. Based on character set size and length.

  - **Seen Entropy**: Assumes attacker knows the dictionary and configuration
    used. Based on the actual number of possible password combinations.

  ## Security Model

  Password strength comes from **entropy** (number of possible combinations)
  and **cryptographically secure randomness**, not from keeping the generation
  method secret.

  ## Entropy Thresholds

  Based on NIST and OWASP guidelines:

  - **< 40 bits**: Weak - DO NOT USE (crackable in minutes/hours)
  - **40-52 bits**: Fair - Minimal acceptable (crackable in days/months)
  - **52-78 bits**: Good - Recommended for most uses (years to centuries)
  - **78+ bits**: Excellent - High security (millennia+)

  ## Examples

      iex> config = ExkPasswd.Config.new!(num_words: 3)
      iex> password = ExkPasswd.generate(config)
      iex> result = ExkPasswd.Entropy.calculate(password, config)
      iex> result.blind > 40
      true
      iex> result.seen > 50
      true

      iex> ExkPasswd.Entropy.calculate_seen(ExkPasswd.Config.new!(num_words: 6))
      iex> # Returns entropy in bits (float)
  """

  alias ExkPasswd.{Config, Dictionary}

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
  Calculate comprehensive entropy metrics for a password and settings.

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
      iex> password = "12-HAPPY-forest-DANCE-bird-56"
      iex> result = ExkPasswd.Entropy.calculate(password, config)
      iex> is_float(result.blind) and is_float(result.seen)
      true
  """
  @spec calculate(String.t(), Config.t()) :: entropy_result()
  def calculate(password, settings) do
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
  Calculate blind entropy from a password string.

  Analyzes the actual password to determine alphabet size (character types used)
  and calculates entropy based on brute-force attack assumptions.

  Formula: Eb = log₂(A^L)
  - A = alphabet size (number of unique character types)
  - L = password length

  ## Parameters

  - `password` - The password string to analyze

  ## Returns

  Entropy in bits (float)

  ## Examples

      iex> ExkPasswd.Entropy.calculate_blind("aB3!")
      iex> # ~26.3 bits for 4-char with mixed types

      iex> blind = ExkPasswd.Entropy.calculate_blind("correcthorsebatterystaple")
      iex> blind > 100
      true
  """
  @spec calculate_blind(String.t()) :: float()
  def calculate_blind(password) do
    alphabet_size = detect_alphabet_size(password)
    length = String.length(password)

    if length == 0 do
      0.0
    else
      :math.log2(:math.pow(alphabet_size, length))
    end
  end

  @doc """
  Calculate seen entropy from settings.

  Calculates entropy assuming attacker knows the dictionary and configuration.
  This is the "true" entropy based on the number of possible combinations.

  ## Parameters

  - `config` - The Config struct

  ## Returns

  Entropy in bits (float)

  ## Examples

      iex> config = ExkPasswd.Config.new!(num_words: 3)
      iex> seen = ExkPasswd.Entropy.calculate_seen(config)
      iex> seen > 40
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
      iex> result = ExkPasswd.Entropy.calculate_seen_detailed(config)
      iex> is_float(result.total)
      true
  """
  @spec calculate_seen_detailed(Config.t()) :: map()
  def calculate_seen_detailed(settings) do
    word_entropy = calculate_word_entropy(settings)
    separator_entropy = calculate_separator_entropy(settings)
    padding_entropy = calculate_padding_entropy(settings)
    digit_entropy = calculate_digit_entropy(settings)
    case_entropy = calculate_case_entropy(settings)
    substitution_entropy = calculate_substitution_entropy(settings)

    total =
      word_entropy + separator_entropy + padding_entropy + digit_entropy + case_entropy +
        substitution_entropy

    %{
      total: total,
      word_entropy: word_entropy,
      separator_entropy: separator_entropy,
      padding_entropy: padding_entropy,
      digit_entropy: digit_entropy,
      case_entropy: case_entropy,
      substitution_entropy: substitution_entropy
    }
  end

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
    # Use the lower of the two as the limiting factor
    effective_entropy = min(blind, seen)

    cond do
      effective_entropy >= @entropy_min_excellent -> :excellent
      effective_entropy >= @entropy_min_good -> :good
      effective_entropy >= @entropy_min_fair -> :fair
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
      iex> String.contains?(time, "minute") or String.contains?(time, "second")
      true

      iex> time = ExkPasswd.Entropy.estimate_crack_time(80)
      iex> String.contains?(time, "year") or String.contains?(time, "centur")
      true
  """
  @spec estimate_crack_time(float()) :: String.t()
  def estimate_crack_time(entropy_bits) do
    # Total combinations = 2^entropy_bits
    total_combinations = :math.pow(2, entropy_bits)

    # Average time to crack (assuming found at 50% of search space)
    seconds = total_combinations / (2 * @guesses_per_second)

    format_time(seconds)
  end

  defp detect_alphabet_size(password) do
    graphemes = String.graphemes(password)

    has_lowercase = Enum.any?(graphemes, &(&1 =~ ~r/[a-z]/))
    has_uppercase = Enum.any?(graphemes, &(&1 =~ ~r/[A-Z]/))
    has_digits = Enum.any?(graphemes, &(&1 =~ ~r/[0-9]/))
    has_symbols = Enum.any?(graphemes, &(&1 =~ ~r/[^a-zA-Z0-9]/))

    alphabet_size = 0
    alphabet_size = if has_lowercase, do: alphabet_size + 26, else: alphabet_size
    alphabet_size = if has_uppercase, do: alphabet_size + 26, else: alphabet_size
    alphabet_size = if has_digits, do: alphabet_size + 10, else: alphabet_size
    # Approximate symbol count (common symbols)
    alphabet_size = if has_symbols, do: alphabet_size + 33, else: alphabet_size

    max(alphabet_size, 1)
  end

  defp calculate_word_entropy(config) do
    word_count =
      Dictionary.count_between(
        config.word_length.first,
        config.word_length.last
      )

    if word_count == 0 do
      0.0
    else
      :math.log2(:math.pow(word_count, config.num_words))
    end
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

    cond do
      char_count == 0 -> 0.0
      config.padding.to_length > 0 -> :math.log2(char_count)
      config.padding.before > 0 or config.padding.after > 0 -> :math.log2(char_count)
      true -> 0.0
    end
  end

  defp calculate_digit_entropy(config) do
    before_entropy =
      if elem(config.digits, 0) > 0 do
        :math.log2(:math.pow(10, elem(config.digits, 0)))
      else
        0.0
      end

    after_entropy =
      if elem(config.digits, 1) > 0 do
        :math.log2(:math.pow(10, elem(config.digits, 1)))
      else
        0.0
      end

    before_entropy + after_entropy
  end

  defp calculate_case_entropy(config) do
    case config.case_transform do
      # Random case adds 1 bit per word (choice of upper or lower)
      :random -> config.num_words * 1.0
      # All other transforms are deterministic
      _ -> 0.0
    end
  end

  defp calculate_substitution_entropy(config) do
    case Map.get(config, :substitution_mode, :none) do
      :random ->
        # Each word has 50% chance of substitution = 1 bit per word
        config.num_words * 1.0

      :always ->
        # Deterministic, no entropy
        0.0

      :none ->
        0.0
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

  defp format_time(seconds) when seconds < 315_360_000_000 do
    centuries = seconds / 3_153_600_000
    "#{Float.round(centuries, 1)} centuries"
  end

  defp format_time(seconds) when seconds < 31_536_000_000_000 do
    millennia = seconds / 31_536_000_000
    "#{Float.round(millennia, 1)} millennia"
  end

  defp format_time(_) do
    "billions of years"
  end
end
