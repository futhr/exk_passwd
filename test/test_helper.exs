ExUnit.start()

# Start Config.Presets Agent for tests that don't use start_supervised
case ExkPasswd.Config.Presets.start_link([]) do
  {:ok, _} -> :ok
  {:error, {:already_started, _}} -> :ok
end
