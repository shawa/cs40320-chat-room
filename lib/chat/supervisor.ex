defmodule Chat.Supervisor do
  require Logger
  use Supervisor


  def start_link do
    Supervisor.start_link(__MODULE__, [], name: :chat_supervisor)
  end

  def start_room(name) do
    Supervisor.start_child(:chat_supervisor, [name])
  end

  def get_room(name) do
    case :gproc.where({:n, :l, {:chat_room, name}}) do
      :undefined -> {:error, :does_not_exist}
      pid        -> {:ok, pid}
    end
  end

  def init(_) do
    children = [
      worker(Chat.Rooms, []),
    ]

    Logger.info "Chat Supervisor started"
    supervise(children, strategy: :simple_one_for_one)
  end
end
