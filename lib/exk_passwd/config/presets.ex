defmodule ExkPasswd.Config.Presets do
  @moduledoc """
  Preset registry with compile-time and runtime preset support.

  Built-in presets are pre-validated at compile time for zero runtime overhead.
  Custom presets can be registered at runtime for application-specific configurations.

  ## Built-in Presets

  - `:default` - Balanced security and memorability (~59 bits entropy)
  - `:web32` - For websites allowing up to 32 characters (~65 bits)
  - `:web16` - For websites with 16 character limit (~42 bits - ⚠️ low security)
  - `:wifi` - 63 character WPA2 keys (~85 bits)
  - `:apple_id` - Meets Apple ID requirements (~55 bits)
  - `:security` - For security questions (~77 bits)
  - `:xkcd` - Similar to the famous XKCD comic (~65 bits)

  ## Examples

      # Get a built-in preset
      config = Presets.get(:xkcd)

      # Register a custom preset
      Presets.register(:corporate,
        Config.new!(num_words: 4, separator: "-")
      )

      # Compose from existing preset
      Presets.register(:strong_wifi,
        Presets.get(:wifi),
        num_words: 8
      )

      # List all presets
      Presets.list()
      #=> [:default, :web32, :web16, :wifi, :apple_id, :security, :xkcd, :corporate, :strong_wifi]
  """

  use Agent

  alias ExkPasswd.Config

  # Pre-validated compile-time presets
  @builtin_presets %{
    default:
      Config.new!(
        num_words: 3,
        word_length: 4..8,
        case_transform: :alternate,
        separator: ~s(!@$%^&*-_+=:|~?/.;),
        digits: {2, 2},
        padding: %{
          char: ~s(!@$%^&*-_+=:|~?/.;),
          before: 2,
          after: 2,
          to_length: 0
        },
        substitutions: %{},
        substitution_mode: :none,
        dictionary: :eff,
        meta: %{
          name: "default",
          description:
            "The default preset resulting in a password consisting of 3 random words " <>
              "of between 4 and 8 letters with alternating case separated by a random character, " <>
              "with two random digits before and after, and padded with two random characters front and back."
        }
      ),
    web32:
      Config.new!(
        num_words: 4,
        word_length: 4..5,
        case_transform: :alternate,
        separator: ~s(-+=.*_|~),
        digits: {2, 3},
        padding: %{
          char: ~s(!@$%^&*+=:|~),
          before: 1,
          after: 1,
          to_length: 0
        },
        dictionary: :eff,
        meta: %{
          name: "web32",
          description: "A preset for websites that allow passwords up to 32 characters long."
        }
      ),
    web16:
      Config.new!(
        num_words: 3,
        word_length: 4..4,
        case_transform: :random,
        separator: ~s(!@$%^&*-_+=:|~?/.),
        digits: {0, 1},
        padding: %{
          char: "",
          before: 0,
          after: 0,
          to_length: 0
        },
        dictionary: :eff,
        meta: %{
          name: "web16",
          description:
            "A preset for websites that insist passwords not be longer than 16 characters. " <>
              "WARNING - only use this preset if you have to, it is too short to be acceptably secure."
        }
      ),
    wifi:
      Config.new!(
        num_words: 6,
        word_length: 4..8,
        case_transform: :alternate,
        separator: ~s(-+=.*_|~,),
        digits: {4, 4},
        padding: %{
          char: ~s(!@$%^&*+=:|~?),
          before: 0,
          after: 0,
          to_length: 63
        },
        dictionary: :eff,
        meta: %{
          name: "wifi",
          description:
            "A preset for generating 63 character long WPA2 keys " <>
              "(most routers allow 64 characters, but some only 63, hence the odd length)."
        }
      ),
    apple_id:
      Config.new!(
        num_words: 3,
        word_length: 4..7,
        case_transform: :random,
        separator: ~s(-:.@&),
        digits: {2, 2},
        padding: %{
          char: ~s(-:.!?@&),
          before: 1,
          after: 1,
          to_length: 0
        },
        dictionary: :eff,
        meta: %{
          name: "apple_id",
          description:
            "A preset respecting the many prerequisites Apple places on Apple ID passwords. " <>
              "The preset also limits itself to symbols found on the iOS letter and number keyboards."
        }
      ),
    security:
      Config.new!(
        num_words: 6,
        word_length: 4..8,
        case_transform: :none,
        separator: " ",
        digits: {0, 0},
        padding: %{
          char: ~s(.!?),
          before: 0,
          after: 1,
          to_length: 0
        },
        dictionary: :eff,
        meta: %{
          name: "security",
          description: "A preset for creating fake answers to security questions."
        }
      ),
    xkcd:
      Config.new!(
        num_words: 5,
        word_length: 4..8,
        case_transform: :random,
        separator: "-",
        digits: {0, 0},
        padding: %{
          char: "",
          before: 0,
          after: 0,
          to_length: 0
        },
        dictionary: :eff,
        meta: %{
          name: "xkcd",
          description:
            "A preset for generating passwords similar to the example in the original XKCD cartoon, " <>
              "but with an extra word, a dash to separate the random words, " <>
              "and the capitalization randomized to add sufficient entropy to avoid warnings."
        }
      )
  }

  @doc """
  Start the preset registry Agent.

  This is typically called by the application supervisor.
  """
  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  @doc """
  Get a preset by name.

  Checks built-in presets first (compile-time, zero overhead), then runtime registry.

  ## Parameters

  - `name` - Preset name as atom or string

  ## Returns

  A Config struct or `nil` if not found.

  ## Examples

      config = Presets.get(:xkcd)
      config = Presets.get("wifi")
      config = Presets.get(:nonexistent)
      #=> nil
  """
  @spec get(atom() | String.t()) :: Config.t() | nil
  def get(name) when is_atom(name) do
    Map.get(@builtin_presets, name) || get_runtime(name)
  end

  def get(name) when is_binary(name) do
    atom_name = try_string_to_atom(name)
    if atom_name, do: get(atom_name), else: get_runtime(name)
  end

  @doc """
  Register a runtime preset.

  ## Parameters

  - `name` - Preset name (atom)
  - `config` - A validated Config struct

  ## Returns

  `:ok`

  ## Examples

      Presets.register(:corporate,
        Config.new!(num_words: 4, separator: "-")
      )
  """
  @spec register(atom(), Config.t()) :: :ok
  def register(name, %Config{} = config) when is_atom(name) do
    Agent.update(__MODULE__, &Map.put(&1, name, config))
  end

  @doc """
  Register a preset by composing from a base with overrides.

  ## Parameters

  - `name` - New preset name (atom)
  - `base` - Base preset name (atom) or Config struct
  - `overrides` - Keyword list of overrides

  ## Returns

  `:ok`

  ## Examples

      # Extend built-in preset
      Presets.register(:strong_wifi, :wifi, num_words: 8, digits: {6, 6})

      # Extend custom preset
      base = Config.new!(num_words: 3)
      Presets.register(:custom, base, separator: "_")
  """
  @spec register(atom(), atom() | Config.t(), keyword()) :: :ok
  def register(name, base, overrides) when is_atom(base) and is_list(overrides) do
    config =
      base
      |> get()
      |> Config.new!(overrides)

    register(name, config)
  end

  def register(name, %Config{} = base, overrides) when is_list(overrides) do
    config = Config.new!(base, overrides)
    register(name, config)
  end

  @doc """
  List all available preset names (built-in and runtime).

  ## Returns

  List of preset names as atoms.

  ## Examples

      Presets.list()
      #=> [:default, :web32, :web16, :wifi, :apple_id, :security, :xkcd]
  """
  @spec list() :: [atom()]
  def list do
    builtin = Map.keys(@builtin_presets)
    runtime = Agent.get(__MODULE__, &Map.keys(&1))
    Enum.uniq(builtin ++ runtime)
  end

  @doc """
  Get all built-in presets as a list.

  ## Returns

  List of Config structs.

  ## Examples

      all = Presets.all()
      length(all)
      #=> 7
  """
  @spec all() :: [Config.t()]
  def all do
    Map.values(@builtin_presets)
  end

  # Private helpers

  defp get_runtime(name) when is_atom(name) do
    Agent.get(__MODULE__, &Map.get(&1, name))
  end

  defp get_runtime(_name), do: nil

  defp try_string_to_atom(string) do
    String.to_existing_atom(string)
  rescue
    ArgumentError -> nil
  end
end
