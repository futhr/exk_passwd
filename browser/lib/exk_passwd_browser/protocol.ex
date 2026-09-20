defmodule ExkPasswdBrowser.Protocol do
  @moduledoc false

  alias ExkPasswd.Config
  alias ExkPasswd.Config.Presets

  @browser_core_version "0.1.0"
  @dictionary_checksum "18586c092f641ecd1a471dd6ab35618ab69f0aa7483486424f7caf0996d06259"
  @dictionary_words 7_772
  @fission_vm_commit "6c3208c7b3dbc7dacc35a19f8de1fa80b358ac73"
  @popcorn_version "0.3.3"
  @presets [
    {"default", :default},
    {"xkcd", :xkcd},
    {"web32", :web32},
    {"web16", :web16},
    {"wifi", :wifi},
    {"apple_id", :apple_id},
    {"security", :security}
  ]
  @case_modes %{
    "none" => :none,
    "alternate" => :alternate,
    "capitalize" => :capitalize,
    "invert" => :invert,
    "lower" => :lower,
    "upper" => :upper,
    "random" => :random
  }
  @substitution_modes %{"none" => :none, "always" => :always, "random" => :random}

  @type response :: {:ok, map()} | {:error, String.t(), String.t()}

  @spec handle(term()) :: response()
  def handle(%{"action" => "generate", "settings" => settings}) when is_map(settings) do
    with {:ok, config} <- config_from(settings) do
      password = ExkPasswd.generate(config)

      {:ok,
       %{
         "password" => password,
         "entropy" => entropy(password, config),
         "config" => describe_config(config)
       }}
    end
  rescue
    error in ArgumentError -> invalid(error.message)
    _error -> {:error, "generation_failed", "Password generation failed closed."}
  end

  def handle(%{"action" => "calculate_entropy", "password" => password, "settings" => settings})
      when is_binary(password) and is_map(settings) do
    with {:ok, config} <- config_from(settings) do
      {:ok, %{"entropy" => entropy(password, config)}}
    end
  rescue
    error in ArgumentError -> invalid(error.message)
    _error -> {:error, "entropy_failed", "Entropy calculation failed closed."}
  end

  def handle(%{"action" => "presets"}) do
    presets =
      Enum.map(@presets, fn {name, preset} ->
        config = Presets.get(preset)

        %{
          "name" => name,
          "description" => config.meta.description,
          "config" => describe_config(config)
        }
      end)

    {:ok, %{"presets" => presets}}
  end

  def handle(%{"action" => "runtime_info"}) do
    {:ok,
     %{
       "browser_core_version" => @browser_core_version,
       "dictionary_checksum" => @dictionary_checksum,
       "dictionary_words" => @dictionary_words,
       "exk_passwd_version" => ExkPasswd.version(),
       "fission_vm_commit" => @fission_vm_commit,
       "popcorn_version" => @popcorn_version,
       "random_source" => "Web Crypto getRandomValues"
     }}
  end

  def handle(_command), do: {:error, "unsupported_command", "Unsupported browser-core command."}

  defp config_from(settings) do
    with {:ok, base} <- preset(settings),
         {:ok, overrides} <- overrides(settings) do
      case Config.merge(base, overrides) do
        {:ok, config} -> {:ok, config}
        {:error, message} -> invalid(message)
      end
    else
      {:error, message} -> invalid(message)
    end
  end

  defp preset(settings) do
    requested = Map.get(settings, "preset", "default")

    case List.keyfind(@presets, requested, 0) do
      {_, name} -> {:ok, Presets.get(name)}
      nil -> {:error, "Unknown preset."}
    end
  end

  defp overrides(settings) do
    with {:ok, case_mode} <- mapped_value(settings, "case_mode", @case_modes),
         {:ok, substitution_mode} <-
           mapped_value(settings, "substitution_mode", @substitution_modes) do
      overrides =
        []
        |> optional_put(:num_words, settings, "num_words")
        |> optional_put(:separator, settings, "separator")
        |> optional_value(:case_transform, case_mode)
        |> optional_value(:substitution_mode, substitution_mode)
        |> optional_digits(settings)
        |> optional_padding(settings)

      {:ok, overrides}
    end
  end

  defp mapped_value(settings, key, values) do
    case Map.fetch(settings, key) do
      :error ->
        {:ok, nil}

      {:ok, value} ->
        case Map.fetch(values, value) do
          {:ok, mapped} -> {:ok, mapped}
          :error -> {:error, "Invalid #{key}."}
        end
    end
  end

  defp optional_put(options, option, settings, key) do
    case Map.fetch(settings, key) do
      :error -> options
      {:ok, value} -> Keyword.put(options, option, value)
    end
  end

  defp optional_value(options, _option, nil), do: options
  defp optional_value(options, option, value), do: Keyword.put(options, option, value)

  defp optional_digits(options, settings) do
    case {Map.fetch(settings, "digits_before"), Map.fetch(settings, "digits_after")} do
      {:error, :error} ->
        options

      {before, after_digits} ->
        Keyword.put(options, :digits, {value(before, 0), value(after_digits, 0)})
    end
  end

  defp optional_padding(options, settings) do
    keys = ["padding_char", "padding_before", "padding_after", "padding_to_length"]

    if Enum.any?(keys, &Map.has_key?(settings, &1)) do
      padding = %{
        char: Map.get(settings, "padding_char", ""),
        before: Map.get(settings, "padding_before", 0),
        after: Map.get(settings, "padding_after", 0),
        to_length: Map.get(settings, "padding_to_length", 0)
      }

      Keyword.put(options, :padding, padding)
    else
      options
    end
  end

  defp value({:ok, value}, _default), do: value
  defp value(:error, default), do: default

  defp entropy(password, config) do
    result = ExkPasswd.calculate_entropy(password, config)

    %{
      "blind" => result.blind,
      "seen" => result.seen,
      "status" => Atom.to_string(result.status),
      "blind_crack_time" => result.blind_crack_time,
      "seen_crack_time" => result.seen_crack_time,
      "details" => stringify_keys(result.details)
    }
  end

  defp stringify_keys(map) do
    Map.new(map, fn {key, value} -> {Atom.to_string(key), value} end)
  end

  defp describe_config(config) do
    %{
      "case_mode" => Atom.to_string(config.case_transform),
      "digits_after" => elem(config.digits, 1),
      "digits_before" => elem(config.digits, 0),
      "num_words" => config.num_words,
      "padding_after" => config.padding.after,
      "padding_before" => config.padding.before,
      "padding_char" => config.padding.char,
      "padding_to_length" => config.padding.to_length,
      "separator" => config.separator,
      "substitution_mode" => Atom.to_string(config.substitution_mode),
      "word_length_max" => config.word_length.last,
      "word_length_min" => config.word_length.first
    }
  end

  defp invalid(message), do: {:error, "invalid_settings", message}
end
