ExUnit.start()

# Start Config.Presets Agent for tests that don't use start_supervised
case ExkPasswd.Config.Presets.start_link([]) do
  {:ok, _pid} -> :ok
  {:error, {:already_started, _pid}} -> :ok
end
