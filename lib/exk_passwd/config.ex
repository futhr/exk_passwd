defmodule ExkPasswd.Config do
  @moduledoc """
  Modern schema-driven configuration system for password generation.

  This module provides a flexible, extensible configuration approach that supports:
  - Declarative schema validation
  - Composition and merging
  - Custom validators via behaviours
  - Runtime extensibility through meta field
  - Protocol-based transformations

  ## Examples

      # Create from keyword list
      {:ok, config} = Config.new(num_words: 4, separator: "-")

      # Create from map
      {:ok, config} = Config.new(%{num_words: 4})

      # Compose from another config
      {:ok, config} = Config.new(base_config, num_words: 5)

      # Raise on error
      config = Config.new!(num_words: 4, separator: "-")

      # With custom validators
      config = Config.new!(
        num_words: 4,
        validators: [MyApp.CustomValidator]
      )

      # With metadata for plugins
      config = Config.new!(
        num_words: 3,
        meta: %{plugin_data: "custom"}
      )
  """

  alias ExkPasswd.Config.Schema

  @default_padding %{char: ~s(!@$%^&*-_+=:|~?/.;), before: 2, after: 2, to_length: 0}

  @type case_transform :: :none | :alternate | :capitalize | :invert | :lower | :upper | :random
  @type substitution_mode :: :none | :always | :random

  @derive {Inspect,
           only: [
             :num_words,
             :word_length,
             :case_transform,
             :separator,
             :digits,
             :padding,
             :substitution_mode,
             :dictionary
           ]}

  @type t :: %__MODULE__{
          num_words: pos_integer(),
          word_length: Range.t(),
          case_transform: case_transform(),
          separator: String.t(),
          digits: {non_neg_integer(), non_neg_integer()},
          padding: map(),
          substitutions: %{String.t() => String.t()},
          substitution_mode: substitution_mode(),
          dictionary: atom(),
          meta: map(),
          validators: [module()],
          word_length_bounds: Range.t() | nil
        }

  @enforce_keys []
  defstruct num_words: 3,
            word_length: 4..8,
            case_transform: :alternate,
            separator: ~s(!@$%^&*-_+=:|~?/.;),
            digits: {2, 2},
            padding: @default_padding,
            substitutions: %{},
            substitution_mode: :none,
            dictionary: :eff,
            meta: %{},
            validators: [],
            word_length_bounds: nil

  @doc """
  Create a new configuration from keyword list, map, or another config.

  ## Parameters

  - `opts` - Keyword list, map, or existing Config struct
  - `overrides` - Additional keyword list to merge (when first arg is Config)

  ## Returns

  - `{:ok, config}` if valid
  - `{:error, reason}` if validation fails

  ## Examples

      {:ok, config} = Config.new(num_words: 4, separator: "-")

      {:ok, config} = Config.new(%{num_words: 4})

      # Merge with existing config
      {:ok, config2} = Config.new(config, num_words: 5)

      # Validation error
      {:error, msg} = Config.new(num_words: 0)
  """
  @spec new(keyword() | map() | t(), keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts \\ [], overrides \\ [])

  def new(%__MODULE__{} = config, overrides) when is_list(overrides) do
    config
    |> Map.from_struct()
    |> Map.merge(Map.new(overrides))
    |> new()
  end

  def new(opts, []) when is_list(opts) do
    opts = merge_padding(opts)
    config = struct(__MODULE__, opts)

    with :ok <- Schema.validate(config),
         :ok <- run_custom_validators(config) do
      {:ok, config}
    end
  end

  def new(opts, []) when is_map(opts) do
    opts
    |> Map.to_list()
    |> new()
  end

  @doc """
  Create a new configuration, raising on validation errors.

  ## Parameters

  - `opts` - Keyword list, map, or existing Config struct
  - `overrides` - Additional keyword list to merge

  ## Returns

  The validated Config struct.

  ## Raises

  `ArgumentError` if validation fails.

  ## Examples

      config = Config.new!(num_words: 4, separator: "-")

      config = Config.new!(existing_config, separator: "_")

      # Raises ArgumentError
      Config.new!(num_words: 0)
  """
  @spec new!(keyword() | map() | t(), keyword()) :: t()
  def new!(opts \\ [], overrides \\ []) do
    case new(opts, overrides) do
      {:ok, config} -> config
      {:error, reason} -> raise ArgumentError, reason
    end
  end

  @doc """
  Merge two configurations, with the second taking precedence.

  ## Parameters

  - `base` - Base configuration (Config struct, preset atom, or preset string)
  - `overrides` - Keyword list or map of overrides

  ## Returns

  - `{:ok, config}` if valid
  - `{:error, reason}` if validation fails

  ## Examples

      {:ok, config} = Config.merge(base_config, num_words: 5)

      # Merge with validation
      {:ok, config} = Config.merge(base_config, %{separator: "-"})
  """
  @spec merge(t(), keyword() | map()) :: {:ok, t()} | {:error, String.t()}
  def merge(%__MODULE__{} = base, overrides) when is_list(overrides) or is_map(overrides) do
    new(base, Map.to_list(Map.new(overrides)))
  end

  @doc """
  Merge two configurations, raising on validation errors.

  ## Parameters

  - `base` - Base configuration
  - `overrides` - Keyword list or map of overrides

  ## Returns

  The merged Config struct.

  ## Raises

  `ArgumentError` if validation fails.

  ## Examples

      config = Config.merge!(base_config, num_words: 5)
  """
  @spec merge!(t(), keyword() | map()) :: t()
  def merge!(base, overrides) do
    case merge(base, overrides) do
      {:ok, config} -> config
      {:error, reason} -> raise ArgumentError, reason
    end
  end

  @doc """
  Add a custom validator to the configuration.

  ## Parameters

  - `config` - The configuration to modify
  - `validator_module` - Module implementing ExkPasswd.Validator behaviour

  ## Returns

  Updated configuration with validator added.

  ## Examples

      config = Config.add_validator(config, MyApp.CustomValidator)
  """
  @spec add_validator(t(), module()) :: t()
  def add_validator(%__MODULE__{validators: validators} = config, validator_module) do
    %{config | validators: validators ++ [validator_module]}
  end

  @doc """
  Put metadata into the config's meta field.

  Useful for storing plugin-specific or application-specific data.

  ## Parameters

  - `config` - The configuration to modify
  - `key` - Metadata key
  - `value` - Metadata value

  ## Returns

  Updated configuration.

  ## Examples

      config = Config.put_meta(config, :emoji_mode, true)
      config = Config.put_meta(config, :custom_data, %{foo: "bar"})
  """
  @spec put_meta(t(), atom(), any()) :: t()
  def put_meta(%__MODULE__{meta: meta} = config, key, value) do
    %{config | meta: Map.put(meta, key, value)}
  end

  @doc """
  Get metadata from the config's meta field.

  ## Parameters

  - `config` - The configuration
  - `key` - Metadata key
  - `default` - Default value if key not found

  ## Returns

  The metadata value or default.

  ## Examples

      value = Config.get_meta(config, :emoji_mode, false)
  """
  @spec get_meta(t(), atom(), any()) :: any()
  def get_meta(%__MODULE__{meta: meta}, key, default \\ nil) do
    Map.get(meta, key, default)
  end

  defp merge_padding(opts) do
    case Keyword.has_key?(opts, :padding) do
      true ->
        {_current_value, updated_opts} =
          Keyword.get_and_update(opts, :padding, &{&1, Map.merge(@default_padding, &1)})

        updated_opts

      false ->
        opts
    end
  end

  defp run_custom_validators(%__MODULE__{validators: []}), do: :ok

  defp run_custom_validators(%__MODULE__{validators: validators} = config) do
    Enum.reduce_while(validators, :ok, fn validator_mod, :ok ->
      case validator_mod.validate(config) do
        :ok -> {:cont, :ok}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end
end
