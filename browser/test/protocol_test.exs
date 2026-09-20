defmodule ExkPasswdBrowser.ProtocolTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias ExkPasswd.Random.Source
  alias ExkPasswdBrowser.CounterSource
  alias ExkPasswdBrowser.Protocol

  setup do
    CounterSource.reset()
    :ok
  end

  test "matches the deterministic browser generation vector" do
    response =
      Source.with_source(CounterSource, fn ->
        Protocol.handle(%{"action" => "generate", "settings" => %{"preset" => "default"}})
      end)

    assert {:ok, %{"config" => config, "entropy" => entropy, "password" => password}} = response
    assert password == "++07!most!EVOKE!think!08++"
    assert_in_delta entropy["seen"], 59.4, 0.1
    assert_in_delta entropy["blind"], 170.8, 0.1
    assert config["case_mode"] == "alternate"
    assert config["num_words"] == 3
    assert config["separator"] == "!@$%^&*-_+=:|~?/.;"
  end

  test "calculates entropy without generating a password" do
    command = %{
      "action" => "calculate_entropy",
      "password" => "correct-horse-battery-staple",
      "settings" => %{"preset" => "xkcd"}
    }

    assert {:ok, %{"entropy" => entropy}} = Protocol.handle(command)
    assert entropy["blind"] > 0.0
    assert entropy["seen"] > 0.0
    assert entropy["status"] in ["weak", "fair", "good", "excellent"]
  end

  test "returns every supported preset" do
    assert {:ok, %{"presets" => presets}} = Protocol.handle(%{"action" => "presets"})

    assert Enum.map(presets, & &1["name"]) == [
             "default",
             "xkcd",
             "web32",
             "web16",
             "wifi",
             "apple_id",
             "security"
           ]

    assert Enum.all?(presets, &is_binary(&1["description"]))
  end

  test "reports the pinned browser runtime identity" do
    assert {:ok, %{"browser_core_version" => "0.1.0"} = info} =
             Protocol.handle(%{"action" => "runtime_info"})

    assert info["dictionary_words"] == 7_772
    assert info["exk_passwd_version"] == ExkPasswd.version()
    assert info["popcorn_version"] == "0.3.3"
    assert info["random_source"] == "Web Crypto getRandomValues"
  end

  test "rejects unsupported commands and invalid browser settings" do
    assert {:error, "unsupported_command", "Unsupported browser-core command."} =
             Protocol.handle(%{"action" => "unknown"})

    assert {:error, "invalid_settings", "Unknown preset."} =
             Protocol.handle(%{"action" => "generate", "settings" => %{"preset" => "missing"}})

    assert {:error, "invalid_settings", message} =
             Protocol.handle(%{
               "action" => "generate",
               "settings" => %{"preset" => "xkcd", "separator" => "★"}
             })

    assert message == "separator supports ASCII symbols in the browser runtime"
  end
end
