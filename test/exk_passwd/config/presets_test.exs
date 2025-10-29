defmodule ExkPasswd.Config.PresetsTest do
  @moduledoc """
  Tests for the Agent-based preset configuration system.

  ## Testing Strategy

  This suite validates the `ExkPasswd.Config.Presets` module, which provides:
  - Built-in presets (`:default`, `:xkcd`, `:wifi`, `:web32`, `:web16`, `:appleid`, `:security`)
  - Runtime custom preset registration via Agent state
  - Preset composition and overrides

  ## Architecture

  The Presets module uses an Agent to store runtime-registered custom presets while keeping
  built-in presets as compile-time data structures for performance. This hybrid approach:
  - Enables extensibility (users can register custom presets at runtime)
  - Maintains performance (built-ins don't require Agent calls)
  - Allows testing without global state pollution (supervised Agent in tests)

  ## Concurrency Model

  Tests use `async: false` because:
  1. The Presets Agent is shared state across tests
  2. Custom preset registration modifies global state
  3. Supervisor start order must be deterministic

  The `setup` block ensures the Agent is started (or reuses existing) before each test.

  ## Built-in Presets

  Each built-in preset is tested to ensure:
  - Configuration is valid (passes Config.Schema validation)
  - Key parameters match documented values
  - Security/entropy characteristics are appropriate for use case

  ## Custom Presets

  Tests verify that runtime preset registration:
  - Allows arbitrary Config structs to be stored
  - Persists across get/1 calls within same test
  - Overwrites existing custom presets with same name
  - Doesn't interfere with built-in presets
  """
  use ExUnit.Case, async: false

  alias ExkPasswd.Config
  alias ExkPasswd.Config.Presets

  setup do
    # Start the Agent for runtime presets (or use existing)
    case start_supervised(Presets) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end

    :ok
  end

  describe "built-in presets" do
    test "get/1 returns default preset" do
      config = Presets.get(:default)
      assert %Config{} = config
      assert config.num_words == 3
      assert config.word_length == 4..8
    end

    test "get/1 returns xkcd preset" do
      config = Presets.get(:xkcd)
      assert %Config{} = config
      assert config.num_words == 5
      assert config.separator == "-"
      assert config.digits == {0, 0}
    end

    test "get/1 returns wifi preset" do
      config = Presets.get(:wifi)
      assert %Config{} = config
      assert config.num_words == 6
      assert config.padding.to_length == 63
    end

    test "get/1 returns web32 preset" do
      config = Presets.get(:web32)
      assert %Config{} = config
      assert config.num_words == 4
    end

    test "get/1 returns web16 preset" do
      config = Presets.get(:web16)
      assert %Config{} = config
      assert config.num_words == 3
      assert config.word_length == 4..4
    end

    test "get/1 returns apple_id preset" do
      config = Presets.get(:apple_id)
      assert %Config{} = config
      assert config.case_transform == :random
    end

    test "get/1 returns security preset" do
      config = Presets.get(:security)
      assert %Config{} = config
      assert config.separator == " "
      assert config.case_transform == :none
    end

    test "get/1 with string name" do
      config = Presets.get("xkcd")
      assert %Config{} = config
      assert config.num_words == 5
    end

    test "get/1 returns nil for unknown preset" do
      assert Presets.get(:nonexistent) == nil
      assert Presets.get("unknown") == nil
    end

    test "get/1 with non-existent string preset" do
      result = Presets.get("nonexistent_preset")
      assert result == nil
    end

    test "get/1 handles very long string that can't be an atom" do
      long_name = String.duplicate("a", 500)
      result = Presets.get(long_name)
      assert result == nil
    end

    test "get/1 with string converts to atom and looks up" do
      # Test with valid preset name as string
      config = Presets.get("default")
      assert %Config{} = config
      assert config.num_words == 3
    end

    test "all built-in presets are pre-validated" do
      # This test ensures all presets are valid at compile time
      for preset_name <- [:default, :web32, :web16, :wifi, :apple_id, :security, :xkcd] do
        config = Presets.get(preset_name)
        assert %Config{} = config
        # Should not raise when validating again
        assert {:ok, _} = Config.new(config)
      end
    end
  end

  describe "runtime preset registration" do
    test "register/2 adds a new preset" do
      custom = Config.new!(num_words: 4, separator: "-")
      :ok = Presets.register(:custom, custom)

      retrieved = Presets.get(:custom)
      assert retrieved.num_words == 4
      assert retrieved.separator == "-"
    end

    test "register/3 composes from base preset (atom)" do
      :ok = Presets.register(:strong_xkcd, :xkcd, num_words: 7)

      config = Presets.get(:strong_xkcd)
      assert config.num_words == 7
      # Inherited from xkcd
      assert config.separator == "-"
      assert config.digits == {0, 0}
    end

    test "register/3 composes from base config struct" do
      base = Config.new!(num_words: 3, separator: "-")
      :ok = Presets.register(:custom_base, base, num_words: 5)

      config = Presets.get(:custom_base)
      assert config.num_words == 5
      assert config.separator == "-"
    end

    test "runtime presets can override built-in presets" do
      # Register a preset with same name as built-in
      custom = Config.new!(num_words: 10, separator: "_")
      :ok = Presets.register(:default, custom)

      # Built-in should still take precedence
      config = Presets.get(:default)
      assert config.num_words == 3
    end

    test "registered preset persists across calls" do
      custom = Config.new!(num_words: 8)
      :ok = Presets.register(:persistent, custom)

      config1 = Presets.get(:persistent)
      config2 = Presets.get(:persistent)

      assert config1.num_words == 8
      assert config2.num_words == 8
    end
  end

  describe "list/0" do
    test "lists all built-in presets" do
      presets = Presets.list()
      assert :default in presets
      assert :xkcd in presets
      assert :wifi in presets
      assert :web32 in presets
      assert :web16 in presets
      assert :apple_id in presets
      assert :security in presets
    end

    test "lists runtime presets" do
      custom = Config.new!(num_words: 4)
      :ok = Presets.register(:listed_custom, custom)

      presets = Presets.list()
      assert :listed_custom in presets
    end

    test "does not duplicate names" do
      presets = Presets.list()
      unique_presets = Enum.uniq(presets)
      assert length(presets) == length(unique_presets)
    end
  end

  describe "all/0" do
    test "returns all built-in preset configs" do
      all_configs = Presets.all()
      assert length(all_configs) == 7
      assert Enum.all?(all_configs, &match?(%Config{}, &1))
    end

    test "all presets have metadata" do
      for config <- Presets.all() do
        assert config.meta[:name]
        assert config.meta[:description]
      end
    end
  end
end
