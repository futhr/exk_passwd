defmodule ExkPasswd.Validator do
  @moduledoc """
  Behaviour for custom configuration validators.

  Implement this behaviour to add custom validation logic to your configurations.
  Validators are called after schema validation passes.

  ## Implementing a Validator

  Create a module that implements the `validate/1` callback:

      defmodule MyApp.CorporateValidator do
        @behaviour ExkPasswd.Validator

        @impl true
        def validate(config) do
          cond do
            config.num_words < 4 ->
              {:error, "Corporate policy requires at least 4 words"}

            config.separator not in ["-", "_"] ->
              {:error, "Corporate policy allows only - or _ separators"}

            true ->
              :ok
          end
        end
      end

  ## Using Validators

  Pass validators to `ExkPasswd.Config.new!/1` via the `:validators` option:

      config = ExkPasswd.Config.new!(
        num_words: 4,
        separator: "-",
        validators: [MyApp.CorporateValidator]
      )

  Multiple validators are applied in sequence. All must return `:ok` for
  the configuration to be valid.

  ## Callback

  The behaviour requires a single callback:

  - `validate(config)` - Returns `:ok` or `{:error, reason}`
  """

  alias ExkPasswd.Config

  @doc """
  Validate a configuration.

  Implementations should inspect the config and return `:ok` if valid,
  or `{:error, reason}` with a descriptive error message if invalid.

  ## Parameters

  - `config` - The `%ExkPasswd.Config{}` struct to validate

  ## Returns

  - `:ok` if the configuration passes validation
  - `{:error, reason}` if invalid, where `reason` is a descriptive string
  """
  @callback validate(Config.t()) :: :ok | {:error, String.t()}

  @doc """
  Run a list of validators against a configuration.

  Each validator module must implement the `ExkPasswd.Validator` behaviour.
  Validators are called in order; the first failure stops execution.

  ## Parameters

  - `config` - The `%ExkPasswd.Config{}` struct to validate
  - `validators` - List of modules implementing `ExkPasswd.Validator`

  ## Returns

  - `:ok` if all validators pass
  - `{:error, reason}` from the first validator that fails

  ## Examples

      iex> defmodule TestVal do
      ...>   @behaviour ExkPasswd.Validator
      ...>   @impl true
      ...>   def validate(_config), do: :ok
      ...> end
      ...>
      ...> ExkPasswd.Validator.run_all(%ExkPasswd.Config{}, [TestVal])
      :ok
  """
  @spec run_all(Config.t(), [module()]) :: :ok | {:error, String.t()}
  def run_all(_, []), do: :ok

  def run_all(config, [validator | rest]) do
    case validator.validate(config) do
      :ok -> run_all(config, rest)
      {:error, _} = error -> error
    end
  end
end
