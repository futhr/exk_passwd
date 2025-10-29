defmodule ExkPasswd.ValidatorTest do
  @moduledoc """
  Tests for the Validator behaviour.
  """
  use ExUnit.Case, async: true

  alias ExkPasswd.{Config, Validator}

  defmodule TestValidator do
    @behaviour Validator

    @impl true
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

    @impl true
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
end
