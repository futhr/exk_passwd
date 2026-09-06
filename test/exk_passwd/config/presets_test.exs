defmodule ExkPasswd.Config.PresetsTest do
  @moduledoc false

  use ExUnit.Case, async: false

  alias ExkPasswd.Config
  alias ExkPasswd.Config.Presets

  setup do
    start_supervised!(Presets)

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
      assert config.case_transform == :alternate
    end

    test "apple_id outputs meet documented composition rules" do
      for _ <- 1..50 do
        password = ExkPasswd.generate(:apple_id)

        assert String.length(password) >= 8
        assert password =~ ~r/[a-z]/
        assert password =~ ~r/[A-Z]/
        assert password =~ ~r/[0-9]/
        refute password =~ ~r/(.)\1\1/u
      end
    end

    test "wifi outputs are 63 printable ASCII characters" do
      for _ <- 1..20 do
        password = ExkPasswd.generate(:wifi)
        assert String.length(password) == 63
        assert password =~ ~r/^[\x20-\x7E]{63}$/
      end
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
      assert is_nil(Presets.get(:nonexistent))
      assert is_nil(Presets.get("unknown"))
    end

    test "get/1 with non-existent string preset" do
      result = Presets.get("nonexistent_preset")
      assert is_nil(result)
    end

    test "get/1 handles very long string that can't be an atom" do
      long_name = String.duplicate("a", 500)
      result = Presets.get(long_name)
      assert is_nil(result)
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
    test "each test starts with an empty runtime registry" do
      assert Enum.sort(Presets.list()) ==
               Enum.sort(Enum.map(Presets.all(), &String.to_existing_atom(&1.meta.name)))
    end

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

    test "built-in presets take precedence over runtime registration" do
      # Registering a preset with the same name as a built-in is allowed,
      # but get/1 resolves built-ins first
      custom = Config.new!(num_words: 10, separator: "_")
      :ok = Presets.register(:default, custom)

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

defmodule ExkPasswd.Config.PresetsWithoutRegistryTest do
  @moduledoc false

  # The registry has a global name; keep these tests synchronous.
  use ExUnit.Case, async: false

  alias ExkPasswd.Config
  alias ExkPasswd.Config.Presets

  test "get/1 resolves built-in presets without the registry" do
    assert %Config{num_words: 5} = Presets.get(:xkcd)
    assert %Config{} = Presets.get("wifi")
  end

  test "get/1 returns nil for unknown presets instead of exiting" do
    assert is_nil(Presets.get(:nonexistent))
    assert is_nil(Presets.get("nonexistent"))
  end

  test "list/0 returns built-in presets only" do
    assert Enum.sort(Presets.list()) ==
             Enum.sort([:default, :web32, :web16, :wifi, :apple_id, :security, :xkcd])
  end

  test "register/2 raises with supervision tree instructions" do
    custom = Config.new!(num_words: 4)

    assert_raise RuntimeError, ~r/supervision tree/, fn ->
      Presets.register(:needs_agent, custom)
    end
  end

  test "register/3 raises with supervision tree instructions" do
    assert_raise RuntimeError, ~r/supervision tree/, fn ->
      Presets.register(:needs_agent, :xkcd, num_words: 7)
    end
  end

  test "ExkPasswd.generate/1 raises ArgumentError for unknown preset names" do
    assert_raise ArgumentError, ~r/[Uu]nknown preset/, fn ->
      ExkPasswd.generate(:no_such_preset)
    end
  end

  test "ExkPasswd.generate/1 works with built-in presets" do
    password = ExkPasswd.generate(:xkcd)
    assert is_binary(password)
    assert password != ""
  end
end
