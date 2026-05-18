defmodule ExkPasswd.ValidatorTest do
  @moduledoc false

  use ExUnit.Case, async: true
  doctest ExkPasswd.Validator

  alias ExkPasswd.{Config, Validator}

  defmodule TestValidator do
    @behaviour Validator

    @impl Validator
    def validate(config) do
      if config.num_words >= 4 do
        :ok
      else
        {:error, "Must have at least 4 words"}
      end
    end
  end

  defmodule TestValidator2 do
    @behaviour Validator

    @impl Validator
    def validate(config) do
      if config.separator != "~" do
        :ok
      else
        {:error, "Cannot use ~ separator"}
      end
    end
  end

  describe "custom validators" do
    test "custom validator is called during config creation" do
      config =
        Config.new!(
          num_words: 5,
          validators: [TestValidator]
        )

      assert config.num_words == 5
    end

    test "custom validator rejects invalid config" do
      assert_raise ArgumentError, ~r/Must have at least 4 words/, fn ->
        Config.new!(
          num_words: 2,
          validators: [TestValidator]
        )
      end
    end

    test "multiple validators are chained" do
      config =
        Config.new!(
          num_words: 4,
          separator: "-",
          validators: [TestValidator, TestValidator2]
        )

      assert config.num_words == 4
      assert config.separator == "-"
    end

    test "all validators must pass" do
      assert_raise ArgumentError, ~r/Cannot use ~ separator/, fn ->
        Config.new!(
          num_words: 5,
          separator: "~",
          validators: [TestValidator, TestValidator2]
        )
      end
    end
  end

  describe "run_all/2" do
    test "returns :ok for empty validator list" do
      config = Config.new!()
      assert Validator.run_all(config, []) == :ok
    end

    test "returns :ok when all validators pass" do
      config = Config.new!(num_words: 5, separator: "-")
      assert Validator.run_all(config, [TestValidator, TestValidator2]) == :ok
    end

    test "returns error from first failing validator" do
      config = Config.new!(num_words: 2, separator: "-")
      assert {:error, "Must have at least 4 words"} = Validator.run_all(config, [TestValidator])
    end

    test "stops at first failure in chain" do
      config = Config.new!(num_words: 2, separator: "~")

      # TestValidator fails first (num_words < 4)
      assert {:error, "Must have at least 4 words"} =
               Validator.run_all(config, [TestValidator, TestValidator2])
    end

    test "second validator can fail" do
      config = Config.new!(num_words: 5, separator: "~")

      # TestValidator passes, TestValidator2 fails
      assert {:error, "Cannot use ~ separator"} =
               Validator.run_all(config, [TestValidator, TestValidator2])
    end
  end
end
