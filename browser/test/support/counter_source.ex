defmodule ExkPasswdBrowser.CounterSource do
  @moduledoc false

  @behaviour ExkPasswd.Random.Source

  @counter_key {__MODULE__, :counter}

  @spec reset() :: integer() | nil
  def reset, do: Process.put(@counter_key, 0)

  @impl ExkPasswd.Random.Source
  @spec strong_bytes(non_neg_integer()) :: binary()
  def strong_bytes(0), do: <<>>

  def strong_bytes(count) when is_integer(count) and count > 0 do
    counter = Process.get(@counter_key, 0)
    bytes = for offset <- 0..(count - 1), into: <<>>, do: <<rem(counter + offset, 256)>>
    Process.put(@counter_key, counter + count)
    bytes
  end
end
