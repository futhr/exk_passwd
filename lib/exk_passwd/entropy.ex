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

  - **< 40 bits**: Weak
  - **40-52 bits**: Fair
  - **52-78 bits**: Good
  - **78+ bits**: Excellent

  These names are presentation labels, not standards-based suitability claims.

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

  # Project-defined rating bands in bits
  @entropy_min_excellent 78
  @entropy_min_good 52
  @entropy_min_fair 40

  # Simple comparison rate; real online and offline rates vary widely.
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

  Returns component entropy estimates plus `:composition_loss`. The total is
  their sum minus this deduction, bounded below by zero. Component values alone
  must not be added as a security estimate.

  For ASCII letter words with punctuation separators, component boundaries are
  recoverable. For other layouts, the deduction bounds collisions using output
  byte-length distributions and removes separator/padding credit. This can be
  deliberately pessimistic. Unknown random transforms or empty word pools return
  a zero total. Distributions are reused within this call, never cached across
  dictionary replacements.

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
    {word_details, layout} = calculate_word_entropy(settings)
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

    composition_loss =
      composition_loss(settings, layout, total, separator_entropy + padding_entropy)

    %{
      total: max(total - composition_loss, 0.0),
      composition_loss: composition_loss,
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

  Uses a comparison rate of one billion guesses per second and an average search
  of half the space. This is not a prediction for a particular verifier or hash.

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
    if config.dictionary == :eff and
         (config.substitution_mode == :none or map_size(config.substitutions) == 0) and
         Config.get_meta(config, :transforms, []) == [] do
      calculate_builtin_word_entropy(config)
    else
      calculate_transformed_word_entropy(config)
    end
  end

  # The bundled lowercase ASCII dictionary has bijective deterministic casing,
  # disjoint upper/lower outputs, and no case-dependent length changes.
  defp calculate_builtin_word_entropy(config) do
    counts = Enum.map(config.word_length, &Dictionary.count_between(&1, &1))
    count = Enum.sum(counts)
    bits = if count == 0, do: 0.0, else: :math.log2(count)

    case_bits =
      if count > 0 and config.case_transform == :random, do: config.num_words * 1.0, else: 0.0

    parts = %{word: bits * config.num_words, case: case_bits, substitution: 0.0, transform: 0.0}

    layout =
      if count == 0 do
        :unknown
      else
        %{letters?: true, loss: :math.log2(Enum.count(counts, &(&1 > 0)))}
      end

    {parts, [{layout, config.num_words}]}
  end

  defp calculate_transformed_word_entropy(config) do
    base_entropy =
      config
      |> dictionary_words(:none)
      |> uniform_distribution()
      |> distribution_entropy()

    positions =
      if config.case_transform == :alternate do
        [{0, div(config.num_words + 1, 2)}, {1, div(config.num_words, 2)}]
      else
        [{0, config.num_words}]
      end

    positions
    |> Enum.reject(fn {_, count} -> count == 0 end)
    |> Enum.map(fn {position, count} ->
      {parts, layout} = word_entropy_for_position(config, position, base_entropy)
      {Map.new(parts, fn {key, value} -> {key, value * count} end), {layout, count}}
    end)
    |> Enum.reduce({%{word: 0.0, case: 0.0, substitution: 0.0, transform: 0.0}, []}, fn
      {parts, layout}, {acc, layouts} ->
        {Map.merge(acc, parts, fn _, left, right -> left + right end), [layout | layouts]}
    end)
  end

  defp calculate_separator_entropy(%{num_words: 1, digits: {0, 0}}), do: 0.0
  defp calculate_separator_entropy(config), do: symbol_entropy(config.separator)

  defp calculate_padding_entropy(config) do
    if config.padding.to_length == 0 and
         (config.padding.before > 0 or config.padding.after > 0) do
      symbol_entropy(config.padding.char)
    else
      0.0
    end
  end

  defp symbol_entropy(""), do: 0.0

  defp symbol_entropy(pool) do
    pool
    |> String.graphemes()
    |> uniform_distribution()
    |> distribution_entropy()
  end

  # Letter-only words and ASCII punctuation have recoverable component boundaries.
  # Other layouts use a lower bound: for each possible vector of word byte lengths,
  # a given output has at most one word tuple once separator/padding are fixed.
  defp composition_loss(config, layouts, total, symbol_bits) do
    cond do
      Enum.any?(layouts, fn {layout, _} -> layout == :unknown end) ->
        total

      unambiguous_layout?(config, layouts) ->
        0.0

      true ->
        length_loss = Enum.sum(Enum.map(layouts, fn {layout, count} -> layout.loss * count end))
        min(total, length_loss + symbol_bits)
    end
  end

  defp unambiguous_layout?(config, layouts) do
    (config.num_words == 1 or config.separator != "") and
      ascii_symbols?(config.separator) and ascii_symbols?(config.padding.char) and
      Enum.all?(layouts, fn {layout, _} -> layout.letters? end)
  end

  defp ascii_symbols?(string),
    do: Regex.match?(~r/\A[\x20-\x2F\x3A-\x40\x5B-\x60\x7B-\x7E]*\z/, string)

  defp distribution_layout(:unknown_random_transform), do: :unknown
  defp distribution_layout(distribution) when map_size(distribution) == 0, do: :unknown

  defp distribution_layout(distribution) do
    length_probability =
      distribution
      |> Enum.reduce(%{}, fn {word, probability}, acc ->
        Map.update(acc, byte_size(word), probability, &max(&1, probability))
      end)
      |> Map.values()
      |> Enum.sum()

    %{
      letters?:
        Enum.all?(distribution, fn {word, _} -> Regex.match?(~r/\A[a-zA-Z]+\z/, word) end),
      loss: max(distribution_entropy(distribution) + :math.log2(length_probability), 0.0)
    }
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

    final_distribution =
      case apply_meta_transforms(substitution_distribution, config) do
        {:ok, distribution} -> distribution
        :unknown_random_transform -> :unknown_random_transform
      end

    final_entropy =
      if is_map(final_distribution), do: distribution_entropy(final_distribution), else: 0.0

    parts = allocate_word_entropy(base_entropy, case_entropy, substitution_entropy, final_entropy)
    {parts, distribution_layout(final_distribution)}
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

    Enum.reduce(words, %{}, fn word, acc ->
      Map.update(acc, word, probability, &(&1 + probability))
    end)
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
