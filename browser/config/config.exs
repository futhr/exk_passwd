import Config

config :exk_passwd, atomvm_browser: true

config :popcorn,
  extra_apps: [:crypto],
  out_dir: "_release/core",
  treeshake: true

if File.exists?("config/#{config_env()}.exs") do
  import_config "#{config_env()}.exs"
end
