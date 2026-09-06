defmodule ExkPasswd.QualityGateTest do
  @moduledoc false

  use ExUnit.Case, async: true

  test "pull requests and releases run the canonical gate on the same runtime" do
    ci = File.read!(".github/workflows/ci.yml")
    publish = File.read!(".github/workflows/publish.yml")

    assert ci =~ "pull_request:"

    for workflow <- [ci, publish] do
      assert workflow =~ "run: mix check --no-retry"
    end

    for key <- ["elixir-version", "otp-version"] do
      pattern = Regex.compile!(key <> ": \"([^\"]+)\"")
      assert Regex.run(pattern, ci) == Regex.run(pattern, publish)
    end

    [gate, publish_step] = String.split(publish, "- name: Publish to Hex.pm")
    assert gate =~ "run: mix check --no-retry"
    refute gate =~ "secrets.HEX_API_KEY"
    assert publish_step =~ "secrets.HEX_API_KEY"
  end

  test "Dialyzer caches are separated by runtime and environment" do
    config = Mix.Project.config()[:dialyzer]
    refute Keyword.has_key?(config, :plt_file)
    assert config[:plt_local_path] == "priv/plts"
  end

  test "development tools are not pulled into test or production applications" do
    for {name, _, options} <- Mix.Project.config()[:deps],
        name not in [:castore, :excoveralls] do
      assert options[:only] in [:dev, [:dev]], "#{name} leaks into the test environment"
    end

    assert File.read!(".github/workflows/ci.yml") =~ "MIX_ENV: test"
  end

  test "coverage output from the gate matches the CI upload" do
    {config, _} = Code.eval_file(".check.exs")
    tools = config[:tools]
    assert tools[:test][:command] == "mix coveralls.json"
    assert tools[:test][:env] == %{"MIX_ENV" => "test"}
    assert tools[:doctor] == "mix doctor --summary"
    assert File.read!(".github/workflows/ci.yml") =~ "files: cover/excoveralls.json"
  end
end
