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
    @spec apply(ExkPasswd.Transform.CaseTransform.t(), String.t(), ExkPasswd.Config.t()) ::
            String.t()
    def apply(%{mode: :upper}, word, _), do: String.upcase(word)
    def apply(%{mode: :lower}, word, _), do: String.downcase(word)
    def apply(%{mode: :capitalize}, word, _), do: String.capitalize(word)
    def apply(%{mode: :none}, word, _), do: word

    def apply(%{mode: :invert}, word, _) do
      case String.next_codepoint(word) do
        {head, rest} -> String.downcase(head) <> String.upcase(rest)
        nil -> word
      end
    end

    def apply(%{mode: :random}, word, _) do
      if Random.boolean() do
        String.upcase(word)
      else
        String.downcase(word)
      end
    end

    @spec entropy_bits(ExkPasswd.Transform.CaseTransform.t(), ExkPasswd.Config.t()) :: float()
    def entropy_bits(%{mode: :random}, config) do
      # Each word adds 1 bit of entropy (upper or lower)
      config.num_words * 1.0
    end

    def entropy_bits(_, _) do
      # Deterministic transforms add no entropy
      0.0
    end
  end
end
