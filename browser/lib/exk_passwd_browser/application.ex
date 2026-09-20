defmodule ExkPasswdBrowser.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [ExkPasswdBrowser.Server]
    Supervisor.start_link(children, strategy: :one_for_one, name: ExkPasswdBrowser.Supervisor)
  end
end
