defmodule ExkPasswd.Transform.CaseTransform do
  @moduledoc """
  Built-in case transformation implementation.

  This transform handles the standard case transformations:
  - `:upper` - All uppercase
  - `:lower` - All lowercase
  - `:capitalize` - First letter uppercase
  - `:invert` - First letter lowercase, rest uppercase
  - `:random` - Randomly upper or lower (adds entropy)
  - `:none` - No transformation

  ## Examples

      transform = %ExkPasswd.Transform.CaseTransform{mode: :upper}
      ExkPasswd.Transform.apply(transform, "hello", config)
      #=> "HELLO"

      transform = %ExkPasswd.Transform.CaseTransform{mode: :random}
      ExkPasswd.Transform.apply(transform, "hello", config)
      #=> "HELLO" or "hello" (random)
  """

  alias ExkPasswd.Random

  defstruct [:mode]

  @type t :: %__MODULE__{
          mode: :none | :upper | :lower | :capitalize | :invert | :random
        }

  defimpl ExkPasswd.Transform do
    def apply(%{mode: :upper}, word, _config), do: String.upcase(word)
    def apply(%{mode: :lower}, word, _config), do: String.downcase(word)
    def apply(%{mode: :capitalize}, word, _config), do: String.capitalize(word)
    def apply(%{mode: :none}, word, _config), do: word

    def apply(%{mode: :invert}, word, _config) do
      case String.next_codepoint(word) do
        {head, rest} -> String.downcase(head) <> String.upcase(rest)
        nil -> word
      end
    end

    def apply(%{mode: :random}, word, _config) do
      if Random.boolean() do
        String.upcase(word)
      else
        String.downcase(word)
      end
    end

    # Entropy calculation
    def entropy_bits(%{mode: :random}, config) do
      # Each word adds 1 bit of entropy (upper or lower)
      config.num_words * 1.0
    end

    def entropy_bits(_, _config) do
      # Deterministic transforms add no entropy
      0.0
    end
  end
end
