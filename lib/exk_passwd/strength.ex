defmodule ExkPasswd.Strength do
  @moduledoc """
  Password strength assessment based on entropy calculations.

  Provides quantitative strength metrics as pure data, leaving presentation
  and internationalization to consumers.

  ## Examples

      iex> config = ExkPasswd.Config.new!(num_words: 3)
      iex> password = ExkPasswd.generate(config)
      iex> result = ExkPasswd.Strength.analyze(password, config)
      iex> result.rating in [:excellent, :good, :fair, :weak]
      true
      iex> result.score >= 0 and result.score <= 100
      true
  """

  alias ExkPasswd.{Config, Entropy}

  @type rating :: :excellent | :good | :fair | :weak

  @type result :: %{
          rating: rating(),
          score: 0..100,
          entropy_bits: float()
        }

  @doc """
  Analyze password strength based on entropy.

  Returns a strength assessment with rating, score, and entropy measurement.
  Consumers can use this data to build their own UI, messages, or localization.

  ## Parameters

  - `password` - The password to analyze
  - `config` - The Config struct used to generate the password

  ## Returns

  A result map containing:
  - `rating` - Strength rating (`:excellent`, `:good`, `:fair`, or `:weak`)
  - `score` - Normalized score from 0 to 100
  - `entropy_bits` - Effective entropy in bits (conservative estimate)

  ## Examples

      iex> config = ExkPasswd.Config.new!(num_words: 4)
      iex> password = "test-PASS-word-HERE"
      iex> result = ExkPasswd.Strength.analyze(password, config)
      iex> is_map(result)
      true
      iex> Map.keys(result) |> Enum.sort()
      [:entropy_bits, :rating, :score]
  """
  @spec analyze(String.t(), Config.t()) :: result()
  def analyze(password, settings) do
    entropy_result = Entropy.calculate(password, settings)

    # Use the more conservative (lower) of blind and seen entropy
    effective_entropy = min(entropy_result.blind, entropy_result.seen)

    %{
      rating: entropy_to_rating(effective_entropy),
      score: entropy_to_score(effective_entropy),
      entropy_bits: effective_entropy
    }
  end

  @doc """
  Quick strength check - returns just the rating.

  Convenience function when you only need the rating category
  without score or entropy details.

  ## Parameters

  - `password` - Password to check
  - `config` - Config used to generate it

  ## Returns

  Strength rating atom (`:excellent`, `:good`, `:fair`, or `:weak`)

  ## Examples

      iex> config = ExkPasswd.Config.new!(num_words: 6)
      iex> password = ExkPasswd.generate(config)
      iex> rating = ExkPasswd.Strength.rating(password, config)
      iex> rating in [:excellent, :good, :fair, :weak]
      true
  """
  @spec rating(String.t(), Config.t()) :: rating()
  def rating(password, settings) do
    analyze(password, settings).rating
  end

  # Rating thresholds based on NIST/OWASP entropy recommendations
  defp entropy_to_rating(entropy) when entropy >= 78, do: :excellent
  defp entropy_to_rating(entropy) when entropy >= 52, do: :good
  defp entropy_to_rating(entropy) when entropy >= 40, do: :fair
  defp entropy_to_rating(_), do: :weak

  # Map entropy to 0-100 score scale (100+ bits entropy = 100 score)
  defp entropy_to_score(entropy) do
    round(min(entropy, 100))
  end
end
