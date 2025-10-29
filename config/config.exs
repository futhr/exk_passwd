import Config

# Configuration for ExkPasswd
# This is a library, so most configuration is done at runtime via Settings structs

config :exk_passwd,
  # Default password generation settings
  default_length: 16,
  min_length: 8,
  max_length: 128

# Configure logger for minimal output
config :logger,
  level: :warning,
  format: "[$level] $message\n"

# Import environment specific config
if File.exists?("config/#{config_env()}.exs") do
  import_config "#{config_env()}.exs"
end
