defmodule ExkPasswd.Validator do
  @moduledoc """
  Behaviour for custom configuration validators.

  Implement this behaviour to add custom validation logic to your configurations.
  Validators are called after schema validation passes.

  ## Examples

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

      # Use the validator
      config = ExkPasswd.Config.new!(
        num_words: 4,
        separator: "-",
        validators: [MyApp.CorporateValidator]
      )
  """

  alias ExkPasswd.Config

  @doc """
  Validate a configuration.

  ## Parameters

  - `config` - The configuration to validate

  ## Returns

  - `:ok` if valid
  - `{:error, reason}` if invalid
  """
  @callback validate(Config.t()) :: :ok | {:error, String.t()}
end
