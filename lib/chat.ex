defmodule Chat do
  require Logger
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    children = [Chat.Bus, []]
    opts = [strategy: :one_for_one, name: Echo.Supervisor]
    Supervisor.start_link(children, opts)
    Logger.info "going"
  end

end
