defmodule ExkPasswd.Transform.SubstitutionTest do
  use ExUnit.Case, async: true
  doctest ExkPasswd.Transform.Substitution

  alias ExkPasswd.Transform.Substitution
  alias ExkPasswd.{Config, Transform}

  setup do
    config = Config.new!(num_words: 3)
    simple_subs = %{"e" => "3", "o" => "0"}
    {:ok, config: config, subs: simple_subs}
  end

  describe "Substitution.default_substitutions/0" do
    test "returns default substitution map" do
      subs = Substitution.default_substitutions()
      assert is_map(subs)
      assert subs["e"] == "3"
      assert subs["a"] == "@"
      assert subs["o"] == "0"
      assert subs["s"] == "$"
      assert subs["i"] == "!"
      assert subs["l"] == "1"
      assert subs["t"] == "7"
    end
  end

  describe "Substitution.apply/3 with :none mode" do
    test "returns word unchanged", %{config: config} do
      transform = %Substitution{map: %{"e" => "3"}, mode: :none}
      assert Transform.apply(transform, "hello", config) == "hello"
      assert Transform.apply(transform, "test", config) == "test"
    end
  end

  describe "Substitution.apply/3 with :always mode" do
    test "always applies substitutions", %{config: config, subs: subs} do
      transform = %Substitution{map: subs, mode: :always}
      assert Transform.apply(transform, "hello", config) == "h3ll0"
      assert Transform.apply(transform, "one", config) == "0n3"
    end

    test "handles mixed case characters", %{config: config} do
      transform = %Substitution{map: %{"e" => "3"}, mode: :always}
      assert Transform.apply(transform, "Hello", config) == "H3llo"
      assert Transform.apply(transform, "TECH", config) == "T3CH"
    end

    test "handles empty substitution map", %{config: config} do
      transform = %Substitution{map: %{}, mode: :always}
      assert Transform.apply(transform, "hello", config) == "hello"
    end

    test "handles empty word", %{config: config, subs: subs} do
      transform = %Substitution{map: subs, mode: :always}
      assert Transform.apply(transform, "", config) == ""
    end

    test "handles word with no substitutable characters", %{config: config} do
      transform = %Substitution{map: %{"e" => "3"}, mode: :always}
      assert Transform.apply(transform, "xyz", config) == "xyz"
    end

    test "uses default substitutions", %{config: config} do
      subs = Substitution.default_substitutions()
      transform = %Substitution{map: subs, mode: :always}

      result = Transform.apply(transform, "leetspeak", config)
      # l -> 1, e -> 3, e -> 3, t -> 7, s -> $, p -> p, e -> 3, a -> @, k -> k
      assert result == "1337$p3@k"
    end
  end

  describe "Substitution.apply/3 with :random mode" do
    test "randomly applies or doesn't apply substitutions", %{config: config, subs: subs} do
      transform = %Substitution{map: subs, mode: :random}

      # Generate many samples
      results =
        for _ <- 1..100 do
          Transform.apply(transform, "hello", config)
        end

      # Should have both substituted and non-substituted results
      assert "h3ll0" in results
      assert "hello" in results
      assert Enum.all?(results, &(&1 in ["hello", "h3ll0"]))
    end

    test "maintains word length", %{config: config, subs: subs} do
      transform = %Substitution{map: subs, mode: :random}
      word = "hello"
      result = Transform.apply(transform, word, config)
      assert String.length(result) == String.length(word)
    end
  end

  describe "Substitution.entropy_bits/2" do
    test "random mode adds 1 bit per word", %{config: config, subs: subs} do
      transform = %Substitution{map: subs, mode: :random}
      expected_entropy = config.num_words * 1.0
      assert Transform.entropy_bits(transform, config) == expected_entropy
    end

    test "random mode entropy scales with num_words", %{subs: subs} do
      transform = %Substitution{map: subs, mode: :random}

      config2 = Config.new!(num_words: 2)
      assert Transform.entropy_bits(transform, config2) == 2.0

      config5 = Config.new!(num_words: 5)
      assert Transform.entropy_bits(transform, config5) == 5.0
    end

    test "deterministic modes add no entropy", %{config: config, subs: subs} do
      for mode <- [:none, :always] do
        transform = %Substitution{map: subs, mode: mode}
        assert Transform.entropy_bits(transform, config) == 0.0
      end
    end
  end

  describe "Substitution.count_substitutable/2" do
    test "counts substitutable characters correctly" do
      subs = %{"e" => "3", "l" => "1", "o" => "0"}

      assert Substitution.count_substitutable("hello", subs) == 4
      assert Substitution.count_substitutable("one", subs) == 2
      assert Substitution.count_substitutable("test", subs) == 1
      assert Substitution.count_substitutable("xyz", subs) == 0
    end

    test "handles empty string" do
      subs = %{"e" => "3"}
      assert Substitution.count_substitutable("", subs) == 0
    end

    test "handles empty substitution map" do
      assert Substitution.count_substitutable("hello", %{}) == 0
    end

    test "counts mixed case characters" do
      subs = %{"e" => "3"}
      assert Substitution.count_substitutable("EeE", subs) == 3
    end

    test "works with default substitutions" do
      subs = Substitution.default_substitutions()
      count = Substitution.count_substitutable("leetspeak", subs)
      # l, e, e, t, s, e, a = 7 substitutable characters
      assert count == 7
    end
  end

  describe "Substitution edge cases" do
    test "handles unicode characters", %{config: config} do
      # Substitution works on lowercase mapping, "é" != "e"
      transform = %Substitution{map: %{"e" => "3"}, mode: :always}
      # "café" has lowercase "e" at the end, which gets replaced
      assert Transform.apply(transform, "cafe", config) == "caf3"
    end

    test "handles numbers and symbols", %{config: config, subs: subs} do
      transform = %Substitution{map: subs, mode: :always}
      assert Transform.apply(transform, "test123!@#", config) == "t3st123!@#"
    end

    test "handles multiple occurrences of same character", %{config: config} do
      transform = %Substitution{map: %{"e" => "3"}, mode: :always}
      assert Transform.apply(transform, "eeeee", config) == "33333"
    end
  end
end
