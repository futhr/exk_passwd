defmodule ExkPasswd.RandomTest do
  @moduledoc """
  Tests for ExkPasswd.Random cryptographic random utilities.
  """
  use ExUnit.Case, async: true
  doctest ExkPasswd.Random

  alias ExkPasswd.Random

  describe "integer/1" do
    test "generates integer within range" do
      value = Random.integer(100)
      assert is_integer(value)
      assert value >= 0 and value < 100
    end

    test "generates different values" do
      values = for _ <- 1..20, do: Random.integer(1000)
      unique = Enum.uniq(values)
      assert length(unique) >= 10
    end
  end

  describe "select/1" do
    test "selects from list" do
      result = Random.select([1, 2, 3, 4, 5])
      assert result in [1, 2, 3, 4, 5]
    end

    test "selects from single element list" do
      result = Random.select([42])
      assert result == 42
    end

    test "always returns single element" do
      results = for _ <- 1..10, do: Random.select([99])
      assert Enum.all?(results, &(&1 == 99))
    end

    test "returns nil for empty list" do
      result = Random.select([])
      assert result == nil
    end

    test "selects from range" do
      result = Random.select(1..10)
      assert result in 1..10
    end

    test "has uniform distribution" do
      results = for _ <- 1..100, do: Random.select([1, 2, 3])
      # All values should appear
      assert 1 in results
      assert 2 in results
      assert 3 in results
    end
  end

  describe "boolean/0" do
    test "returns boolean" do
      result = Random.boolean()
      assert is_boolean(result)
    end

    test "returns both true and false" do
      results = for _ <- 1..100, do: Random.boolean()
      # Should have both true and false
      assert true in results
      assert false in results
    end

    test "has roughly equal distribution" do
      results = for _ <- 1..1000, do: Random.boolean()
      true_count = Enum.count(results, & &1)
      false_count = Enum.count(results, &(!&1))

      # With 1000 samples, expect roughly 40-60% distribution
      assert true_count > 300
      assert false_count > 300
    end
  end

  describe "integer_between/2" do
    test "generates integer in range" do
      value = Random.integer_between(5, 10)
      assert value >= 5 and value <= 10
    end

    test "handles same min and max" do
      value = Random.integer_between(7, 7)
      assert value == 7
    end

    test "handles reversed arguments" do
      value = Random.integer_between(10, 5)
      assert value >= 5 and value <= 10
    end

    test "generates different values" do
      values = for _ <- 1..50, do: Random.integer_between(1, 100)
      unique = Enum.uniq(values)
      assert length(unique) >= 20
    end

    test "covers full range" do
      values = for _ <- 1..100, do: Random.integer_between(1, 3)
      # Should have all values in range
      assert 1 in values
      assert 2 in values
      assert 3 in values
    end

    test "handles edge case with max=1" do
      value = Random.integer_between(0, 0)
      assert value == 0
    end
  end

  describe "integer/1 edge cases" do
    test "handles very large max values" do
      # Test with a max that will likely trigger rejection sampling
      value = Random.integer(4_294_967_295)
      assert value >= 0 and value < 4_294_967_295
    end

    test "handles max=1 (always returns 0)" do
      value = Random.integer(1)
      assert value == 0
    end

    test "handles max=2 (binary choice)" do
      values = for _ <- 1..20, do: Random.integer(2)
      # Should have both 0 and 1
      assert 0 in values
      assert 1 in values
    end

    test "generates values across full range for large max" do
      # Use a max that doesn't divide evenly into 2^32
      # This tests the rejection sampling path
      max = 3
      values = for _ <- 1..1000, do: Random.integer(max)
      unique = Enum.uniq(values)
      # Should see all possible values
      assert length(unique) == 3
      assert 0 in unique
      assert 1 in unique
      assert 2 in unique
    end
  end
end
