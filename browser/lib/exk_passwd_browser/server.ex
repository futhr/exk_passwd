defmodule ExkPasswdBrowser.Server do
  @moduledoc false

  use GenServer

  require Popcorn.Wasm

  alias ExkPasswdBrowser.Protocol

  @process_name :exk_passwd_browser

  @spec start_link(term()) :: GenServer.on_start()
  def start_link(_args), do: GenServer.start_link(__MODULE__, nil, name: @process_name)

  @impl true
  def init(nil) do
    IO.puts("__EXK_PASSWD_READY__")
    {:ok, nil}
  end

  @impl true
  def handle_info(message, state) when Popcorn.Wasm.is_wasm_message(message) do
    new_state =
      Popcorn.Wasm.handle_message!(message, fn
        {:wasm_call, command} -> {:resolve, reply(command), state}
        {:wasm_cast, _command} -> state
      end)

    {:noreply, new_state}
  end

  def handle_info(_message, state), do: {:noreply, state}

  defp reply(command) do
    case Protocol.handle(command) do
      {:ok, data} ->
        %{"ok" => true, "data" => data}

      {:error, code, message} ->
        %{"ok" => false, "error" => %{"code" => code, "message" => message}}
    end
  end
end
