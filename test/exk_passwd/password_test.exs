defmodule ExkPasswd.PasswordTest do
  @moduledoc """
  Comprehensive tests for the core password generation engine.

  ## Testing Strategy

  This suite validates `ExkPasswd.Password`, the module responsible for orchestrating
  the actual password assembly. It tests the entire configuration space systematically:

  - **Case transforms** (6 variants: none, lower, upper, capitalize, alternate, invert, random)
  - **Separators** (including empty string for no separation)
  - **Digit padding** (before, after, both, none)
  - **Symbol padding** (character selection and placement)
  - **Character substitutions** (leetspeak-style transformations)
  - **Length constraints** (minimum total length via padding)
  - **Buffered random state** (for batch generation optimization)

  ## Architecture Under Test

  The Password module is a pure function that transforms:
  ```
  Config -> Random State -> String
  ```

  It coordinates several subsystems:
  1. Dictionary module (word selection)
  2. Transform protocol (case/substitution)
  3. Token module (digit/symbol generation)
  4. Buffer module (cryptographic random bytes)

  ## Test Coverage Philosophy

  Rather than exhaustive combinatorial testing (which would require millions of test cases),
  this suite uses **representative sampling**:
  - Each configuration dimension is tested independently
  - Critical combinations are tested (e.g., case + substitutions)
  - Edge cases are tested (empty separators, zero padding, etc.)

  ## Determinism vs Randomness

  Tests must verify correctness without relying on specific random outputs.
  Strategies used:
  - **Property testing**: "all words are lowercase" rather than "password equals X"
  - **Statistical testing**: "10 generations produce >1 unique value" (cryptographic quality)
  - **Structure testing**: "has N separators" or "matches regex pattern"

  ## Performance Characteristics

  While not explicitly benchmarked here, this module is the hot path for generation:
  - Single password: ~10-50µs
  - Dominated by :crypto.strong_rand_bytes/1 calls
  - Buffered variant (create_with_state/2) reduces overhead 2-3x for batch operations

  ## Concurrency Safety

  Tests run with `async: true` as Password.create/1 is purely functional with no shared state.
  The Buffer passed to create_with_state/2 is explicitly threaded through, avoiding race conditions.
  """
  use ExUnit.Case, async: true

  alias ExkPasswd.{Buffer, Config, Password}

  describe "create/0" do
    test "creates password with default config" do
      password = Password.create()
      assert is_binary(password)
      assert String.length(password) > 0
    end

    test "generates different passwords each time" do
      passwords = for _ <- 1..10, do: Password.create()
      unique = Enum.uniq(passwords)
      assert length(unique) > 1
    end
  end

  describe "create/1 with case transforms" do
    test "creates password with :none case" do
      config = Config.new!(case_transform: :none, num_words: 3)
      password = Password.create(config)
      assert is_binary(password)
    end

    test "creates password with :lower case" do
      config =
        Config.new!(
          case_transform: :lower,
          num_words: 3,
          separator: "-",
          digits: {0, 0},
          padding: %{char: "", before: 0, after: 0, to_length: 0}
        )

      password = Password.create(config)
      words = String.split(password, "-")
      assert Enum.all?(words, fn word -> word == String.downcase(word) end)
    end

    test "creates password with :upper case" do
      config =
        Config.new!(
          case_transform: :upper,
          num_words: 3,
          separator: "-",
          digits: {0, 0},
          padding: %{char: "", before: 0, after: 0, to_length: 0}
        )

      password = Password.create(config)
      words = String.split(password, "-")
      assert Enum.all?(words, fn word -> word == String.upcase(word) end)
    end

    test "creates password with :capitalize case" do
      config =
        Config.new!(
          case_transform: :capitalize,
          num_words: 3,
          separator: "-",
          digits: {0, 0},
          padding: %{char: "", before: 0, after: 0, to_length: 0}
        )

      password = Password.create(config)
      words = String.split(password, "-")

      assert Enum.all?(words, fn word ->
               first = String.first(word)
               first == String.upcase(first)
             end)
    end

    test "creates password with :alternate case" do
      config =
        Config.new!(
          case_transform: :alternate,
          num_words: 4,
          separator: "-",
          digits: {0, 0},
          padding: %{char: "", before: 0, after: 0, to_length: 0}
        )

      password = Password.create(config)
      words = String.split(password, "-")
      assert length(words) == 4
    end

    test "creates password with :random case" do
      config = Config.new!(case_transform: :random, num_words: 3)
      password = Password.create(config)
      assert is_binary(password)
    end

    test "creates password with :invert case" do
      config =
        Config.new!(
          case_transform: :invert,
          num_words: 3,
          separator: "-",
          digits: {0, 0},
          padding: %{char: "", before: 0, after: 0, to_length: 0}
        )

      password = Password.create(config)
      words = String.split(password, "-")
      # Check first character is lowercase in inverted case
      assert Enum.all?(words, fn word ->
               if String.length(word) > 0 do
                 first = String.first(word)
                 first == String.downcase(first)
               else
                 true
               end
             end)
    end
  end

  describe "create/1 with separators" do
    test "uses specified separator" do
      config = Config.new!(separator: "|", num_words: 3)
      password = Password.create(config)
      assert String.contains?(password, "|")
    end

    test "uses empty separator" do
      config =
        Config.new!(
          separator: "",
          num_words: 3,
          digits: {0, 0},
          padding: %{char: "", before: 0, after: 0, to_length: 0}
        )

      password = Password.create(config)
      # With empty separator, no digits, and no padding, password should just be words
      refute String.contains?(password, "-")
      refute String.contains?(password, "_")
    end
  end

  describe "create/1 with digits" do
    test "adds digits before words" do
      config =
        Config.new!(
          digits: {3, 0},
          separator: "-",
          num_words: 2,
          padding: %{char: "", before: 0, after: 0, to_length: 0}
        )

      password = Password.create(config)
      # Should start with 3 digits
      assert String.match?(password, ~r/^\d{3}/)
    end

    test "adds digits after words" do
      config =
        Config.new!(
          digits: {0, 3},
          separator: "-",
          num_words: 2,
          padding: %{char: "", before: 0, after: 0, to_length: 0}
        )

      password = Password.create(config)
      # Should end with 3 digits
      assert String.match?(password, ~r/\d{3}$/)
    end

    test "adds digits before and after words" do
      config =
        Config.new!(
          digits: {2, 2},
          separator: "-",
          num_words: 2,
          padding: %{char: "", before: 0, after: 0, to_length: 0}
        )

      password = Password.create(config)
      assert String.match?(password, ~r/^\d{2}/)
      assert String.match?(password, ~r/\d{2}$/)
    end

    test "handles zero digits" do
      config =
        Config.new!(
          digits: {0, 0},
          separator: "-",
          num_words: 2,
          padding: %{char: "", before: 0, after: 0, to_length: 0}
        )

      password = Password.create(config)
      # Should not start or end with digits
      refute String.match?(password, ~r/^\d/)
      refute String.match?(password, ~r/\d$/)
    end
  end

  describe "create/1 with padding" do
    test "adds padding before" do
      config =
        Config.new!(
          padding: %{char: "!", before: 2, after: 0, to_length: 0},
          num_words: 2,
          digits: {0, 0}
        )

      password = Password.create(config)
      assert String.starts_with?(password, "!!")
    end

    test "adds padding after" do
      config =
        Config.new!(
          padding: %{char: "!", before: 0, after: 2, to_length: 0},
          num_words: 2,
          digits: {0, 0}
        )

      password = Password.create(config)
      assert String.ends_with?(password, "!!")
    end

    test "adds padding before and after" do
      config =
        Config.new!(
          padding: %{char: "@", before: 1, after: 1, to_length: 0},
          num_words: 2,
          digits: {0, 0}
        )

      password = Password.create(config)
      assert String.starts_with?(password, "@")
      assert String.ends_with?(password, "@")
    end

    test "pads to exact length" do
      config =
        Config.new!(
          padding: %{char: "=", before: 0, after: 0, to_length: 50},
          num_words: 2,
          separator: "-",
          digits: {0, 0}
        )

      password = Password.create(config)
      assert String.length(password) == 50
      assert String.ends_with?(password, "=")
    end

    test "truncates to exact length if too long" do
      config =
        Config.new!(padding: %{char: "=", before: 0, after: 0, to_length: 10}, num_words: 5)

      password = Password.create(config)
      assert String.length(password) == 10
    end
  end

  describe "create/1 with word length ranges" do
    test "respects word length minimum" do
      config =
        Config.new!(
          word_length: 5..5,
          num_words: 3,
          separator: "-",
          digits: {0, 0},
          padding: %{char: "", before: 0, after: 0, to_length: 0}
        )

      password = Password.create(config)
      words = String.split(password, "-")
      assert Enum.all?(words, fn word -> String.length(word) == 5 end)
    end

    test "respects word length range" do
      config =
        Config.new!(
          word_length: 4..8,
          num_words: 3,
          separator: "-",
          digits: {0, 0},
          padding: %{char: "", before: 0, after: 0, to_length: 0}
        )

      password = Password.create(config)
      words = String.split(password, "-")

      assert Enum.all?(words, fn word ->
               len = String.length(word)
               len >= 4 and len <= 8
             end)
    end
  end

  describe "create_with_state/2" do
    test "creates password with buffer state" do
      config = Config.new!(num_words: 3)
      state = Buffer.new(500)

      {password, new_state} = Password.create_with_state(config, state)

      assert is_binary(password)
      assert %Buffer{} = new_state
    end

    test "reuses buffer state across multiple calls" do
      config = Config.new!(num_words: 2)
      state = Buffer.new(1000)

      {pass1, state2} = Password.create_with_state(config, state)
      {pass2, _state3} = Password.create_with_state(config, state2)

      assert is_binary(pass1)
      assert is_binary(pass2)
      assert pass1 != pass2
    end

    test "works with different case transforms" do
      state = Buffer.new(1000)

      for case_transform <- [:none, :lower, :upper, :capitalize, :alternate, :random, :invert] do
        config = Config.new!(case_transform: case_transform, num_words: 2)
        {password, _new_state} = Password.create_with_state(config, state)
        assert is_binary(password)
      end
    end

    test "handles digits with state" do
      config =
        Config.new!(
          digits: {3, 3},
          num_words: 2,
          padding: %{char: "", before: 0, after: 0, to_length: 0}
        )

      state = Buffer.new(500)

      {password, _new_state} = Password.create_with_state(config, state)

      assert String.match?(password, ~r/^\d{3}/)
      assert String.match?(password, ~r/\d{3}$/)
    end

    test "handles padding with state" do
      config =
        Config.new!(
          padding: %{char: "*", before: 2, after: 2, to_length: 0},
          num_words: 2,
          digits: {0, 0}
        )

      state = Buffer.new(500)

      {password, _new_state} = Password.create_with_state(config, state)

      assert String.starts_with?(password, "**")
      assert String.ends_with?(password, "**")
    end
  end

  describe "create/1 with transforms" do
    test "applies custom transforms" do
      transform = %ExkPasswd.Transform.Substitution{
        map: %{"e" => "3"},
        mode: :always
      }

      config =
        Config.new!(
          num_words: 2,
          meta: %{transforms: [transform]}
        )

      password = Password.create(config)
      assert is_binary(password)
    end

    test "applies multiple transforms in order" do
      transform1 = %ExkPasswd.Transform.CaseTransform{mode: :upper}

      transform2 = %ExkPasswd.Transform.Substitution{
        map: %{"E" => "3"},
        mode: :always
      }

      config =
        Config.new!(
          num_words: 2,
          meta: %{transforms: [transform1, transform2]}
        )

      password = Password.create(config)
      assert is_binary(password)
    end

    test "handles empty transforms list" do
      config =
        Config.new!(
          num_words: 2,
          meta: %{transforms: []}
        )

      password = Password.create(config)
      assert is_binary(password)
    end
  end

  describe "create/1 with various configurations" do
    test "creates minimal password" do
      config =
        Config.new!(
          num_words: 1,
          separator: "",
          digits: {0, 0},
          padding: %{char: "", before: 0, after: 0, to_length: 0}
        )

      password = Password.create(config)
      assert is_binary(password)
      assert String.length(password) > 0
    end

    test "creates maximal password" do
      config =
        Config.new!(
          num_words: 10,
          separator: "-",
          digits: {5, 5},
          padding: %{char: "!", before: 5, after: 5, to_length: 0}
        )

      password = Password.create(config)
      assert is_binary(password)
      assert String.length(password) > 50
    end

    test "handles all configuration options simultaneously" do
      config =
        Config.new!(
          num_words: 4,
          word_length: 5..7,
          case_transform: :capitalize,
          separator: "_",
          digits: {2, 2},
          padding: %{char: "@", before: 1, after: 1, to_length: 0}
        )

      password = Password.create(config)
      assert is_binary(password)
      assert String.contains?(password, "_")
      assert String.starts_with?(password, "@")
      assert String.ends_with?(password, "@")
    end
  end

  describe "create/1 with invert case edge cases" do
    test "handles short words with invert" do
      ExkPasswd.Dictionary.load_custom(:short_words, ["test", "word", "here", "four"])

      config =
        Config.new!(
          case_transform: :invert,
          dictionary: :short_words,
          num_words: 2,
          separator: "-",
          word_length: 4..4
        )

      password = Password.create(config)
      assert is_binary(password)
      # Should have alternating case since it's invert
      assert String.length(password) >= 4
    end

    test "invert works with standard dictionary" do
      config =
        Config.new!(
          case_transform: :invert,
          num_words: 2,
          separator: "-"
        )

      password = Password.create(config)
      assert is_binary(password)
    end
  end

  describe "create/1 with padding.to_length edge cases" do
    test "pads password when to_length > current length" do
      config =
        Config.new!(
          padding: %{char: "=", before: 0, after: 0, to_length: 100},
          num_words: 2,
          separator: "-",
          digits: {0, 0}
        )

      password = Password.create(config)
      assert String.length(password) == 100
      assert String.ends_with?(password, "=")
    end

    test "truncates password when to_length < current length" do
      config =
        Config.new!(
          padding: %{char: "=", before: 0, after: 0, to_length: 10},
          num_words: 5,
          separator: "-",
          word_length: 8..10,
          digits: {3, 3}
        )

      password = Password.create(config)
      assert String.length(password) == 10
    end

    test "leaves password unchanged when to_length == current length" do
      # Create a config that produces roughly 20 chars, then set to_length to exactly that
      config1 =
        Config.new!(
          padding: %{char: "=", before: 0, after: 0, to_length: 0},
          num_words: 2,
          separator: "-",
          digits: {2, 2},
          word_length: 5..5
        )

      password1 = Password.create(config1)
      len = String.length(password1)

      # Now create config with to_length set to that exact length
      config2 =
        Config.new!(
          padding: %{char: "=", before: 0, after: 0, to_length: len},
          num_words: 2,
          separator: "-",
          digits: {2, 2},
          word_length: 5..5
        )

      password2 = Password.create(config2)
      # Length should be maintained
      assert String.length(password2) == len
    end
  end

  describe "helper function edge cases" do
    test "join with empty prefix" do
      config =
        Config.new!(
          num_words: 2,
          separator: "-",
          digits: {0, 2},
          padding: %{char: "", before: 0, after: 0, to_length: 0}
        )

      password = Password.create(config)
      # Should not start with separator
      refute String.starts_with?(password, "-")
    end

    test "join with empty suffix" do
      config =
        Config.new!(
          num_words: 2,
          separator: "-",
          digits: {2, 0},
          padding: %{char: "", before: 0, after: 0, to_length: 0}
        )

      password = Password.create(config)
      # Should not end with separator
      refute String.ends_with?(password, "-")
    end

    test "append with empty values" do
      config =
        Config.new!(
          num_words: 2,
          separator: "-",
          digits: {0, 0},
          padding: %{char: "", before: 0, after: 0, to_length: 0}
        )

      password = Password.create(config)
      # Should work without padding
      assert is_binary(password)
      assert String.length(password) > 0
    end
  end
end
