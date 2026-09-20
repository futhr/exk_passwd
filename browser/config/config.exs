import Config

config :exk_passwd, atomvm_browser: true

config :popcorn,
  extra_apps: [:crypto],
  out_dir: "_release/core",
  treeshake: true
