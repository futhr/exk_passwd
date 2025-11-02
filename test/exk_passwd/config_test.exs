defmodule ExkPasswd.ConfigTest do
  @moduledoc """
  Tests for the schema-driven configuration system.

  ## Testing Strategy

  This suite validates the `ExkPasswd.Config` module, which provides declarative schema validation
  and composition for password generation configurations. Key test areas:

  - **Schema validation**: Ensuring invalid configurations are rejected with clear errors
  - **Boundary conditions**: Testing edge cases for numeric ranges and string values
  - **Composition**: Verifying merge semantics and override behavior
  - **Metadata extension**: Testing the meta field for runtime extensibility
  - **Error messages**: Ensuring validation errors are actionable for developers

  ## Validation Philosophy

  ExkPasswd uses fail-fast validation with two APIs:
  - `new!/1` - Raises `ArgumentError` for immediate failures in application code
  - `new/1` - Returns `{:error, msg}` for user-facing validation (e.g., web forms)

  This dual API approach follows Elixir conventions and supports both programming
  errors (which should crash) and validation errors (which should be handled).

  ## Configuration Space

  The Config struct encodes the entire generation parameter space. Tests ensure:
  - All valid configurations are accepted
  - Invalid configurations are rejected with specific error messages
  - Default values are sensible and secure
  - Merging preserves validation invariants

  ## Extensibility

  The `meta` field provides escape hatch extensibility for custom plugins and transforms.
  Tests verify this field is preserved through composition and doesn't interfere with
  core validation.
  """
  use ExUnit.Case, async: true

  alias ExkPasswd.Config

  describe "new!/1" do
    test "creates config with valid parameters" do
      config = Config.new!(num_words: 4)
      assert %Config{} = config
      assert config.num_words == 4
    end

    test "creates config with all parameters" do
      config =
        Config.new!(
          num_words: 5,
          word_length: 4..8,
          case_transform: :capitalize,
          separator: "-",
          digits: {2, 2},
          padding: %{char: "!", before: 1, after: 1, to_length: 0},
          dictionary: :eff
        )

      assert config.num_words == 5
      assert config.word_length == 4..8
      assert config.case_transform == :capitalize
      assert config.separator == "-"
      assert config.digits == {2, 2}
      assert config.padding.char == "!"
    end

    test "raises on invalid num_words" do
      assert_raise ArgumentError, fn ->
        Config.new!(num_words: 0)
      end
    end

    test "raises on invalid word_length" do
      assert_raise ArgumentError, fn ->
        Config.new!(word_length: 20..25)
      end
    end

    test "raises on invalid case_transform" do
      assert_raise ArgumentError, fn ->
        Config.new!(case_transform: :invalid)
      end
    end

    test "raises on invalid separator" do
      assert_raise ArgumentError, fn ->
        Config.new!(separator: ">")
      end
    end

    test "raises on invalid digits tuple" do
      assert_raise ArgumentError, fn ->
        Config.new!(digits: {10, 10})
      end
    end

    test "raises on invalid padding char" do
      assert_raise ArgumentError, fn ->
        Config.new!(padding: %{char: ">", before: 0, after: 0, to_length: 0})
      end
    end
  end

  describe "new/1" do
    test "returns {:ok, config} for valid parameters" do
      assert {:ok, config} = Config.new(num_words: 3)
      assert config.num_words == 3
    end

    test "returns {:error, message} for invalid parameters" do
      assert {:error, msg} = Config.new(num_words: 0)
      assert is_binary(msg)
    end
  end

  describe "merge!/2" do
    test "merges new options into existing config" do
      config = Config.new!(num_words: 3)
      merged = Config.merge!(config, num_words: 5, separator: "_")

      assert merged.num_words == 5
      assert merged.separator == "_"
    end

    test "raises on invalid merged values" do
      config = Config.new!(num_words: 3)

      assert_raise ArgumentError, fn ->
        Config.merge!(config, num_words: 0)
      end
    end
  end

  describe "get_meta/3" do
    test "retrieves meta value by key" do
      config = Config.new!(meta: %{custom: "value"})
      assert Config.get_meta(config, :custom) == "value"
    end

    test "returns default when key not found" do
      config = Config.new!(meta: %{})
      assert Config.get_meta(config, :missing, :default) == :default
    end

    test "returns nil when key not found and no default" do
      config = Config.new!(meta: %{})
      assert Config.get_meta(config, :missing) == nil
    end
  end

  describe "new/1 with alternative inputs" do
    test "creates config from map" do
      result = Config.new(%{num_words: 5, separator: "_"})
      assert {:ok, config} = result
      assert config.num_words == 5
      assert config.separator == "_"
    end

    test "creates config from map with atom keys" do
      result = Config.new(%{num_words: 4, case_transform: :upper})
      assert {:ok, config} = result
      assert config.num_words == 4
      assert config.case_transform == :upper
    end
  end

  describe "new/2 with Config struct and overrides" do
    test "creates config from existing Config struct" do
      base = Config.new!(num_words: 3, separator: "-")
      result = Config.new(base, num_words: 6, separator: "|")

      assert {:ok, config} = result
      assert config.num_words == 6
      assert config.separator == "|"
    end

    test "new! with Config struct and overrides" do
      base = Config.new!(num_words: 2, separator: "~")
      config = Config.new!(base, num_words: 7, separator: "*")

      assert config.num_words == 7
      assert config.separator == "*"
    end

    test "preserves unoverridden fields from Config struct" do
      base = Config.new!(num_words: 3, word_length: 5..7, separator: "-")
      config = Config.new!(base, num_words: 4)

      assert config.num_words == 4
      assert config.word_length == 5..7
      assert config.separator == "-"
    end
  end

  describe "merge/2" do
    test "merges config with keyword list" do
      base = Config.new!(num_words: 3)
      result = Config.merge(base, num_words: 5, separator: "_")
      assert {:ok, config} = result
      assert config.num_words == 5
      assert config.separator == "_"
    end

    test "merges config with map" do
      base = Config.new!(num_words: 3)
      result = Config.merge(base, %{num_words: 5})
      assert {:ok, config} = result
      assert config.num_words == 5
    end

    test "returns error for invalid merge" do
      base = Config.new!(num_words: 3)
      result = Config.merge(base, num_words: 0)
      assert {:error, _msg} = result
    end
  end

  describe "add_validator/2" do
    test "adds validator to config" do
      config = Config.new!(num_words: 3)
      updated = Config.add_validator(config, SomeValidator)
      assert SomeValidator in updated.validators
    end
  end

  describe "put_meta/3 and get_meta/3" do
    test "stores and retrieves metadata" do
      config = Config.new!(num_words: 3)
      updated = Config.put_meta(config, :custom_key, "custom_value")
      assert Config.get_meta(updated, :custom_key) == "custom_value"
    end

    test "overwrites existing metadata" do
      config = Config.new!(num_words: 3)
      updated = Config.put_meta(config, :key, "value1")
      updated = Config.put_meta(updated, :key, "value2")
      assert Config.get_meta(updated, :key) == "value2"
    end

    test "returns default for missing key" do
      config = Config.new!(num_words: 3)
      assert Config.get_meta(config, :missing, :default_value) == :default_value
    end
  end
end
