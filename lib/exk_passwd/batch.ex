defmodule ExkPasswd.Batch do
  @moduledoc """
  Optimized batch password generation with buffered random bytes.

  When generating many passwords at once, this module reduces cryptographic
  overhead by pre-generating a large buffer of random bytes and consuming
  them as needed, rather than making individual `:crypto.strong_rand_bytes/1`
  calls for each random number.

  ## Performance

  For generating many passwords, batch generation reduces syscall overhead by
  using a stateful buffered random generator rather than individual
  `:crypto.strong_rand_bytes/1` calls.

  ## Examples

      iex> passwords = ExkPasswd.Batch.generate_batch(10)
      ...> length(passwords)
      10
      iex> Enum.all?(passwords, &is_binary/1)
      true

      iex> config = ExkPasswd.Config.new!(num_words: 4)
      ...> passwords = ExkPasswd.Batch.generate_batch(5, config)
      ...> length(passwords)
      5
  """

  alias ExkPasswd.{Buffer, Config, Password}

  @default_buffer_size 10_000
  @bytes_per_password_estimate 100

  @doc """
  Generate multiple passwords in batch with optimized random byte buffering.

  This function pre-allocates a buffer of random bytes and uses it to generate
  multiple passwords, reducing the number of expensive `:crypto` syscalls.

  ## Parameters

  - `count` - Number of passwords to generate
  - `config` - Config struct to use (default: default preset)
  - `opts` - Optional keyword list:
    - `:buffer_size` - Size of random byte buffer (default: 10,000 bytes)

  ## Returns

  List of generated passwords

  ## Examples

      iex> passwords = ExkPasswd.Batch.generate_batch(10)
      ...> length(passwords)
      10

      iex> config = ExkPasswd.Config.new!(num_words: 4)
      ...> passwords = ExkPasswd.Batch.generate_batch(5, config)
      ...> length(Enum.uniq(passwords))
      5
  """
  @spec generate_batch(pos_integer(), Config.t(), keyword()) :: [String.t()]
  def generate_batch(count, config \\ Config.new!(), opts \\ []) do
    buffer_size =
      Keyword.get(
        opts,
        :buffer_size,
        max(@default_buffer_size, count * @bytes_per_password_estimate)
      )

    # Create buffered random state
    random_state = Buffer.new(buffer_size)

    {passwords, _} = generate_with_buffer(count, config, random_state, [])

    passwords
  end

  @doc """
  Generate multiple unique passwords in batch.

  Ensures all generated passwords are unique by regenerating duplicates.
  Useful when uniqueness is required (e.g., bulk user creation).

  ## Parameters

  - `count` - Number of unique passwords to generate
  - `config` - Config struct to use
  - `opts` - Optional keyword list:
    - `:max_attempts` - Maximum total generation attempts (default: count * 100)

  ## Returns

  List of unique generated passwords, or raises if max_attempts exceeded

  ## Examples

      iex> alias ExkPasswd.Config
      ...> config = Config.new!(num_words: 4)
      ...> passwords = ExkPasswd.Batch.generate_unique_batch(10, config)
      ...> length(passwords)
      10
      iex> length(Enum.uniq(passwords))
      10
  """
  @spec generate_unique_batch(pos_integer(), Config.t(), keyword()) :: [String.t()]
  @dialyzer {:nowarn_function, generate_unique_batch: 3}
  def generate_unique_batch(count, config \\ Config.new!(), opts \\ []) do
    max_attempts = Keyword.get(opts, :max_attempts, count * 100)
    seen_set = MapSet.new()

    generate_unique_recursive(count, config, seen_set, 0, max_attempts)
  end

  @doc """
  Generate passwords in parallel using multiple processes.

  For very large batches (1000+), parallel generation can provide additional
  speedup on multi-core systems.

  ## Parameters

  - `count` - Number of passwords to generate
  - `config` - Config struct to use
  - `opts` - Optional keyword list:
    - `:workers` - Number of parallel workers (default: System.schedulers_online())

  ## Returns

  List of generated passwords

  ## Examples

      iex> passwords = ExkPasswd.Batch.generate_parallel(100)
      ...> length(passwords)
      100
  """
  @spec generate_parallel(pos_integer(), Config.t(), keyword()) :: [String.t()]
  def generate_parallel(count, config \\ Config.new!(), opts \\ []) do
    workers = Keyword.get(opts, :workers, System.schedulers_online())

    # Divide work among workers
    per_worker = div(count, workers)
    remainder = rem(count, workers)

    # Create tasks for each worker
    tasks =
      for i <- 0..(workers - 1) do
        batch_size = if i < remainder, do: per_worker + 1, else: per_worker

        Task.async(fn ->
          if batch_size > 0 do
            for _ <- 1..batch_size do
              Password.create(config)
            end
          else
            []
          end
        end)
      end

    # Collect results
    tasks
    |> Task.await_many(:infinity)
    |> List.flatten()
  end

  @spec generate_with_buffer(non_neg_integer(), Config.t(), Buffer.t(), [String.t()]) ::
          {[String.t()], Buffer.t()}
  defp generate_with_buffer(0, _config, random_state, acc) do
    {Enum.reverse(acc), random_state}
  end

  defp generate_with_buffer(count, config, random_state, acc) do
    {password, new_random_state} = Password.create_with_state(config, random_state)

    generate_with_buffer(count - 1, config, new_random_state, [password | acc])
  end

  @spec generate_unique_recursive(
          pos_integer(),
          Config.t(),
          MapSet.t(String.t()),
          non_neg_integer(),
          pos_integer()
        ) :: [String.t()]
  defp generate_unique_recursive(count, _config, _seen_set, attempts, max_attempts)
       when attempts >= max_attempts do
    raise "Failed to generate #{count} unique passwords after #{max_attempts} attempts. " <>
            "This suggests very low entropy in the config. " <>
            "Try increasing num_words, word_length_max, or enabling more variation."
  end

  @dialyzer {:nowarn_function, generate_unique_recursive: 5}
  defp generate_unique_recursive(count, config, seen_set, attempts, max_attempts) do
    if MapSet.size(seen_set) >= count do
      MapSet.to_list(seen_set) |> Enum.take(count)
    else
      generate_unique_continue(count, config, seen_set, attempts, max_attempts)
    end
  end

  @spec generate_unique_continue(
          pos_integer(),
          Config.t(),
          MapSet.t(String.t()),
          non_neg_integer(),
          pos_integer()
        ) :: [String.t()]
  defp generate_unique_continue(count, config, seen_set, attempts, max_attempts) do
    password = Password.create(config)

    new_seen_set =
      if MapSet.member?(seen_set, password) do
        seen_set
      else
        MapSet.put(seen_set, password)
      end

    generate_unique_recursive(count, config, new_seen_set, attempts + 1, max_attempts)
  end
end
