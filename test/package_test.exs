defmodule ExkPasswd.PackageTest do
  @moduledoc false

  use ExUnit.Case, async: false

  @tag timeout: 120_000
  test "Hex artifact includes its documentation and runs without development dependencies" do
    directory = Path.join(System.tmp_dir!(), "exk_package_#{System.unique_integer([:positive])}")
    on_exit(fn -> File.rm_rf!(directory) end)

    {output, status} =
      System.cmd("mix", ["hex.build", "--unpack", "--output", directory], stderr_to_stdout: true)

    assert status == 0, output

    docs = Mix.Project.config()[:docs]

    for extra <- docs[:extras] do
      path = if is_tuple(extra), do: elem(extra, 0), else: extra

      assert File.regular?(Path.join(directory, to_string(path))),
             "Missing documentation: #{path}"
    end

    for {source, _} <- docs[:assets] || %{},
        file <- Path.wildcard(Path.join(source, "**/*")),
        File.regular?(file) do
      assert File.regular?(Path.join(directory, file)), "Missing asset: #{file}"
    end

    refute File.exists?(Path.join(directory, "priv/static/xkcd.png"))
    refute File.exists?(Path.join(directory, "priv/plts"))
    refute File.exists?(Path.join(directory, "deps"))

    {:docs_v1, _, _, _, %{"en" => documentation}, _, _} = Code.fetch_docs(ExkPasswd.Transform)
    [_, example] = Regex.run(~r/```elixir\n(.*?)\n```/s, documentation)

    unverifiable =
      example
      |> String.replace("MyApp.ReverseTransform", "MyApp.UnverifiableTransform")
      |> String.replace("do: 0.0", "do: 1.0")

    File.write!(Path.join(directory, "lib/example_transform.ex"), example <> "\n" <> unverifiable)

    options = [
      cd: directory,
      stderr_to_stdout: true,
      env: [
        {"MIX_ENV", "prod"},
        {"MIX_BUILD_PATH", nil},
        {"MIX_BUILD_ROOT", nil},
        {"MIX_DEPS_PATH", nil}
      ]
    ]

    {output, status} =
      System.cmd("mix", ["compile", "--warnings-as-errors", "--no-optional-deps"], options)

    assert status == 0, output

    {output, status} =
      System.cmd(
        "mix",
        [
          "run",
          "--no-compile",
          "-e",
          "true = is_binary(ExkPasswd.generate()); [] = Mix.Project.deps_paths() |> Map.keys(); " <>
            "config = ExkPasswd.Config.new!(meta: %{transforms: [%MyApp.ReverseTransform{}]}); " <>
            "true = is_binary(ExkPasswd.generate(config)); " <>
            "true = ExkPasswd.Entropy.calculate_seen(config) > 40; " <>
            "unknown = ExkPasswd.Config.put_meta(config, :transforms, [%MyApp.UnverifiableTransform{}]); " <>
            "0.0 = ExkPasswd.Entropy.calculate_seen(unknown)"
        ],
        options
      )

    assert status == 0, output
  end
end
