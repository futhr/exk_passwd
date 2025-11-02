defmodule ExkPasswd.Config.SchemaTest do
  @moduledoc """
  Tests for ExkPasswd.Config.Schema validation functions.
  """
  use ExUnit.Case, async: true

  alias ExkPasswd.Config
  alias ExkPasswd.Config.Schema

  describe "validate/1 with word_length" do
    test "validates correct word_length range" do
      config = %Config{word_length: 4..8}
      assert :ok = Schema.validate(config)
    end

    test "rejects word_length with min > max" do
      config = %Config{word_length: 8..4//-1}
      assert {:error, msg} = Schema.validate(config)
      assert msg =~ "min must be <= max"
    end

    test "rejects word_length with out of bounds range" do
      config = %Config{word_length: 2..12}
      assert {:error, msg} = Schema.validate(config)
      assert msg =~ "must be between 4 and 10"
    end

    test "rejects invalid word_length type" do
      config = %Config{word_length: "4..8"}
      assert {:error, msg} = Schema.validate(config)
      assert msg =~ "must be a Range"
    end
  end

  describe "validate/1 with digits" do
    test "validates correct digits tuple" do
      config = %Config{digits: {2, 3}}
      assert :ok = Schema.validate(config)
    end

    test "rejects digits with out of range values" do
      config = %Config{digits: {10, 0}}
      assert {:error, msg} = Schema.validate(config)
      assert msg =~ "must be between 0 and 5"
    end

    test "rejects digits with negative values" do
      config = %Config{digits: {-1, 2}}
      assert {:error, msg} = Schema.validate(config)
      assert msg =~ "must be between 0 and 5"
    end

    test "rejects invalid digits type" do
      config = %Config{digits: [2, 3]}
      assert {:error, msg} = Schema.validate(config)
      assert msg =~ "must be a tuple"
    end
  end

  describe "validate/1 with padding" do
    test "validates correct padding map" do
      config = %Config{padding: %{char: "!", before: 2, after: 2, to_length: 0}}
      assert :ok = Schema.validate(config)
    end

    test "rejects padding.char with invalid type" do
      config = %Config{padding: %{char: 123, before: 0, after: 0, to_length: 0}}
      assert {:error, msg} = Schema.validate(config)
      assert msg =~ "padding.char must be a string"
    end

    test "rejects padding without char key" do
      config = %Config{padding: %{before: 0, after: 0, to_length: 0}}
      assert {:error, msg} = Schema.validate(config)
      assert msg =~ "must have a :char key"
    end

    test "rejects padding.before out of range" do
      config = %Config{padding: %{char: "!", before: 10, after: 0, to_length: 0}}
      assert {:error, msg} = Schema.validate(config)
      assert msg =~ "must be between 0 and 5"
    end

    test "rejects padding.after out of range" do
      config = %Config{padding: %{char: "!", before: 0, after: 10, to_length: 0}}
      assert {:error, msg} = Schema.validate(config)
      assert msg =~ "must be between 0 and 5"
    end

    test "rejects padding without before/after keys" do
      config = %Config{padding: %{char: "!", to_length: 0}}
      assert {:error, msg} = Schema.validate(config)
      assert msg =~ "must have :before and :after keys"
    end

    test "validates padding.to_length = 0" do
      config = %Config{padding: %{char: "!", before: 0, after: 0, to_length: 0}}
      assert :ok = Schema.validate(config)
    end

    test "validates padding.to_length in valid range" do
      config = %Config{padding: %{char: "!", before: 0, after: 0, to_length: 50}}
      assert :ok = Schema.validate(config)
    end

    test "rejects padding.to_length out of range (too small)" do
      config = %Config{padding: %{char: "!", before: 0, after: 0, to_length: 5}}
      assert {:error, msg} = Schema.validate(config)
      assert msg =~ "must be 0 or between 8 and 999"
    end

    test "rejects padding.to_length out of range (too large)" do
      config = %Config{padding: %{char: "!", before: 0, after: 0, to_length: 1000}}
      assert {:error, msg} = Schema.validate(config)
      assert msg =~ "must be 0 or between 8 and 999"
    end

    test "rejects padding without to_length key" do
      config = %Config{padding: %{char: "!", before: 0, after: 0}}
      assert {:error, msg} = Schema.validate(config)
      assert msg =~ "must have a :to_length key"
    end
  end

  describe "validate/1 with substitutions" do
    test "validates correct substitutions map" do
      config = %Config{substitutions: %{"a" => "4", "e" => "3"}}
      assert :ok = Schema.validate(config)
    end

    test "validates empty substitutions map" do
      config = %Config{substitutions: %{}}
      assert :ok = Schema.validate(config)
    end

    test "rejects substitutions with multi-character keys" do
      config = %Config{substitutions: %{"hello" => "w"}}
      assert {:error, msg} = Schema.validate(config)
      assert msg =~ "single-character"
    end

    test "rejects substitutions with multi-character values" do
      config = %Config{substitutions: %{"a" => "world"}}
      assert {:error, msg} = Schema.validate(config)
      assert msg =~ "single-character"
    end

    test "rejects substitutions with non-string keys" do
      config = %Config{substitutions: %{123 => "a"}}
      assert {:error, msg} = Schema.validate(config)
      assert msg =~ "single-character strings"
    end

    test "rejects substitutions with non-string values" do
      config = %Config{substitutions: %{"a" => 123}}
      assert {:error, msg} = Schema.validate(config)
      assert msg =~ "single-character strings"
    end
  end

  describe "validate/1 with case_transform" do
    test "validates all valid case transforms" do
      valid_transforms = [:none, :alternate, :capitalize, :invert, :lower, :upper, :random]

      for transform <- valid_transforms do
        config = %Config{case_transform: transform}
        assert :ok = Schema.validate(config), "Failed for transform: #{transform}"
      end
    end

    test "rejects invalid case_transform" do
      config = %Config{case_transform: :invalid}
      assert {:error, msg} = Schema.validate(config)
      assert msg =~ "must be one of"
    end
  end

  describe "validate/1 with separator" do
    test "validates string separator" do
      config = %Config{separator: "-"}
      assert :ok = Schema.validate(config)
    end

    test "validates empty separator" do
      config = %Config{separator: ""}
      assert :ok = Schema.validate(config)
    end

    test "rejects non-string separator" do
      config = %Config{separator: 123}
      assert {:error, msg} = Schema.validate(config)
      assert msg =~ "separator must be a string"
    end

    test "rejects separator with invalid symbols" do
      config = %Config{separator: ">"}
      assert {:error, msg} = Schema.validate(config)
      assert msg =~ "separator contains invalid symbols"
    end
  end

  describe "validate/1 with num_words edge cases" do
    test "rejects num_words > 10" do
      config = %Config{num_words: 11}
      assert {:error, msg} = Schema.validate(config)
      assert msg =~ "must be between 1 and 10"
    end

    test "rejects non-integer num_words" do
      config = %Config{num_words: "five"}
      assert {:error, msg} = Schema.validate(config)
      assert msg =~ "must be between 1 and 10"
    end
  end

  describe "validate/1 with padding edge cases" do
    test "rejects padding with non-integer before/after" do
      config = %Config{padding: %{char: "!", before: "two", after: 0, to_length: 0}}
      assert {:error, msg} = Schema.validate(config)
      assert msg =~ "must have :before and :after keys with integer values"
    end

    test "rejects padding with invalid to_length type" do
      config = %Config{padding: %{char: "!", before: 0, after: 0, to_length: "fifty"}}
      assert {:error, msg} = Schema.validate(config)
      assert msg =~ "must have a :to_length key with integer value"
    end

    test "rejects padding when it is not a map" do
      config = %Config{padding: "not a map"}
      assert {:error, msg} = Schema.validate(config)
      assert msg =~ "padding must be a map"
    end
  end

  describe "validate/1 with substitution_mode" do
    test "validates :none substitution_mode" do
      config = %Config{substitution_mode: :none}
      assert :ok = Schema.validate(config)
    end

    test "validates :always substitution_mode" do
      config = %Config{substitution_mode: :always}
      assert :ok = Schema.validate(config)
    end

    test "validates :random substitution_mode" do
      config = %Config{substitution_mode: :random}
      assert :ok = Schema.validate(config)
    end

    test "rejects invalid substitution_mode" do
      config = %Config{substitution_mode: :sometimes}
      assert {:error, msg} = Schema.validate(config)
      assert msg =~ "must be one of :none, :always, :random"
    end
  end

  describe "validate/1 with dictionary" do
    test "validates atom dictionary" do
      config = %Config{dictionary: :eff}
      assert :ok = Schema.validate(config)
    end

    test "rejects non-atom dictionary" do
      config = %Config{dictionary: "eff"}
      assert {:error, msg} = Schema.validate(config)
      assert msg =~ "dictionary must be an atom"
    end
  end

  describe "allowed_symbols/0" do
    test "returns list of allowed symbols" do
      symbols = Schema.allowed_symbols()
      assert is_list(symbols)
      assert "-" in symbols
      assert "!" in symbols
      assert "@" in symbols
    end
  end
end
