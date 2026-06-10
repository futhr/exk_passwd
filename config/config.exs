import Config

# ExkPasswd is a library: all generation settings are passed explicitly via
# ExkPasswd.Config structs, never read from application config. This file only
# configures local development tooling.

# Configure logger for minimal output
config :logger,
  level: :warning,
  format: "[$level] $message\n"

# Import environment specific config
if File.exists?("config/#{config_env()}.exs") do
  import_config "#{config_env()}.exs"
end
