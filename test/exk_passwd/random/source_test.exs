defmodule ExkPasswd.Random.SourceTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias ExkPasswd.Random.Source

  defmodule CounterSource do
    @moduledoc false

    @behaviour ExkPasswd.Random.Source
    @counter_key {__MODULE__, :counter}

    @spec reset() :: integer() | nil
    def reset, do: Process.put(@counter_key, 0)

    @impl ExkPasswd.Random.Source
    def strong_bytes(count) do
      counter = Process.get(@counter_key, 0)
      bytes = for offset <- 0..(count - 1), into: <<>>, do: <<rem(counter + offset, 256)>>
      Process.put(@counter_key, counter + count)
      bytes
    end
  end

  test "uses the native cryptographic source by default" do
    bytes = Source.strong_bytes(32)

    assert byte_size(bytes) == 32
    refute bytes == <<0::256>>
  end

  test "allows a deterministic process-local source only in the test build" do
    CounterSource.reset()

    generated =
      Source.with_source(CounterSource, fn ->
        ExkPasswd.generate(ExkPasswd.Config.Presets.get(:default))
      end)

    assert generated == "++07!most!EVOKE!think!08++"
    assert byte_size(Source.strong_bytes(8)) == 8
  end
end
