defmodule ExkPasswd.BufferTest do
  @moduledoc """
  Tests for ExkPasswd.Buffer - buffered random byte generation.
  """
  use ExUnit.Case, async: true
  doctest ExkPasswd.Buffer

  alias ExkPasswd.Buffer

  describe "new/1" do
    test "creates buffer with default size" do
      buffer = Buffer.new()
      assert %Buffer{} = buffer
      assert byte_size(buffer.buffer) == 10000
    end

    test "creates buffer with custom size" do
      buffer = Buffer.new(256)
      assert %Buffer{} = buffer
      assert byte_size(buffer.buffer) == 256
    end

    test "creates buffer with small size" do
      buffer = Buffer.new(8)
      assert %Buffer{} = buffer
      assert byte_size(buffer.buffer) == 8
    end
  end

  describe "random_integer/2" do
    test "returns integer and new state" do
      state = Buffer.new(100)
      {value, new_state} = Buffer.random_integer(state, 100)

      assert is_integer(value)
      assert value >= 0 and value < 100
      assert %Buffer{} = new_state
    end

    test "respects max_value" do
      state = Buffer.new(100)

      results =
        for _ <- 1..20 do
          {value, state} = Buffer.random_integer(state, 10)
          {value, state}
        end
        |> Enum.map(fn {value, _} -> value end)

      assert Enum.all?(results, fn v -> v >= 0 and v < 10 end)
    end

    test "produces different values" do
      state = Buffer.new(1000)

      {values, _final_state} =
        Enum.reduce(1..20, {[], state}, fn _, {acc, st} ->
          {value, new_st} = Buffer.random_integer(st, 1000)
          {[value | acc], new_st}
        end)

      # Should have some variety
      unique_count = Enum.uniq(values) |> length()
      assert unique_count >= 10
    end
  end

  describe "random_element/2" do
    test "selects element from list" do
      state = Buffer.new(100)
      list = ["a", "b", "c", "d", "e"]

      {element, new_state} = Buffer.random_element(state, list)

      assert element in list
      assert %Buffer{} = new_state
    end

    test "returns only element from single-item list" do
      state = Buffer.new(100)
      {element, _} = Buffer.random_element(state, ["only"])

      assert element == "only"
    end

    test "has uniform distribution" do
      state = Buffer.new(1000)
      list = [1, 2, 3]

      results =
        Enum.reduce(1..30, {[], state}, fn _, {acc, state} ->
          {elem, new_state} = Buffer.random_element(state, list)
          {[elem | acc], new_state}
        end)
        |> elem(0)

      # All three elements should appear at least once in 30 selections
      assert 1 in results
      assert 2 in results
      assert 3 in results
    end
  end

  describe "buffer refresh behavior" do
    test "refreshes buffer when exhausted" do
      # Create a very small buffer
      state = Buffer.new(4)

      # Consume it multiple times - this should trigger refresh
      {_val1, state} = Buffer.random_integer(state, 1000)
      {_val2, state} = Buffer.random_integer(state, 1000)
      {_val3, state} = Buffer.random_integer(state, 1000)
      {val4, _state} = Buffer.random_integer(state, 1000)

      # Should still work after multiple operations
      assert is_integer(val4)
      assert val4 >= 0 and val4 < 1000
    end

    test "handles multiple element selections with buffer refresh" do
      state = Buffer.new(5)

      # Select many elements, forcing buffer refresh
      results =
        Enum.reduce(1..10, {[], state}, fn _, {acc, st} ->
          {elem, new_st} = Buffer.random_element(st, [1, 2, 3, 4, 5])
          {[elem | acc], new_st}
        end)
        |> elem(0)

      # Should all be valid elements
      assert Enum.all?(results, fn elem -> elem in [1, 2, 3, 4, 5] end)
      # Should have selected 10 elements
      assert length(results) == 10
    end

    test "buffer state changes with each operation" do
      state1 = Buffer.new(100)
      {_, state2} = Buffer.random_integer(state1, 100)
      {_, state3} = Buffer.random_integer(state2, 100)

      # Offsets should be different
      assert state1.offset != state2.offset
      assert state2.offset != state3.offset
    end

    test "can handle many operations in sequence" do
      state = Buffer.new(50)

      final_state =
        Enum.reduce(1..100, state, fn _, st ->
          {_elem, new_st} = Buffer.random_element(st, ~w[a b c d e])
          new_st
        end)

      # Should still be valid after 100 operations
      assert %Buffer{} = final_state
    end
  end

  describe "random_boolean/1" do
    test "returns boolean and new state" do
      state = Buffer.new(100)
      {value, new_state} = Buffer.random_boolean(state)

      assert is_boolean(value)
      assert %Buffer{} = new_state
    end

    test "produces both true and false" do
      state = Buffer.new(1000)

      {values, _final_state} =
        Enum.reduce(1..50, {[], state}, fn _, {acc, st} ->
          {value, new_st} = Buffer.random_boolean(st)
          {[value | acc], new_st}
        end)

      # Should have both true and false in 50 samples
      assert true in values
      assert false in values
    end
  end

  describe "random_digit/1" do
    test "returns digit and new state" do
      state = Buffer.new(100)
      {digit, new_state} = Buffer.random_digit(state)

      assert is_integer(digit)
      assert digit >= 0 and digit <= 9
      assert %Buffer{} = new_state
    end

    test "produces various digits" do
      state = Buffer.new(1000)

      {digits, _final_state} =
        Enum.reduce(1..100, {[], state}, fn _, {acc, st} ->
          {digit, new_st} = Buffer.random_digit(st)
          {[digit | acc], new_st}
        end)

      # Should have variety in 100 samples
      unique_count = Enum.uniq(digits) |> length()
      assert unique_count >= 5
    end
  end

  describe "edge cases" do
    test "handles large max_value" do
      state = Buffer.new(100)
      {value, _} = Buffer.random_integer(state, 1_000_000)

      assert value >= 0 and value < 1_000_000
    end

    test "handles large list" do
      state = Buffer.new(100)
      large_list = Enum.to_list(1..1000)

      {element, _} = Buffer.random_element(state, large_list)

      assert element in large_list
    end

    test "raises ArgumentError for non-positive max" do
      state = Buffer.new(100)

      assert_raise ArgumentError, "max must be a positive integer, got: 0", fn ->
        Buffer.random_integer(state, 0)
      end

      assert_raise ArgumentError, "max must be a positive integer, got: -5", fn ->
        Buffer.random_integer(state, -5)
      end
    end
  end
end
