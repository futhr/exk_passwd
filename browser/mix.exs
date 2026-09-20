defmodule ExkPasswdBrowser.MixProject do
  use Mix.Project

  def project do
    [
      app: :exk_passwd_browser,
      version: "0.1.0",
      elixir: "1.17.3",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:crypto],
      mod: {ExkPasswdBrowser.Application, []}
    ]
  end

  defp deps do
    [
      {:exk_passwd, "== 0.4.0"},
      {:popcorn, "== 0.3.3"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_environment), do: ["lib"]
end
