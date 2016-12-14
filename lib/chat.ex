defmodule Chat do
  require Logger
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Task, [Chat.Bus, :init, []], restart: :temporary),
      worker(Chat.Supervisor, []),
      supervisor(Task.Supervisor, [[name: Chat.TaskSupervisor]]),
      supervisor(Registry, [:unique, Chat.RoomRegistry, [partitions: System.schedulers_online()]])
    ]
    opts = [strategy: :one_for_one, name: Chat.Supervisor]

    Supervisor.start_link(children, opts)
  end

end
