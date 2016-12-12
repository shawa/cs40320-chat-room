defmodule Chat.Supervisor do
  require Logger
  use Supervisor


  def room_ref room_name do
    {ref, ""} = :crypto.hash(:sha256, room_name)
             |> Base.encode16
             |> Integer.parse(16)
    ref
  end

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: :chat_supervisor)
  end

  def start_room(name) do
    Logger.info "starting #{name}"
    ref = room_ref(name)
    {:ok, pid} = Supervisor.start_child(:chat_supervisor, [ref])
    {:ok, ref}
  end

  def get_room(name) do
    ref = room_ref(name)
    case :gproc.where({:n, :l, {:chat_room, ref}}) do
      :undefined -> {:error, :does_not_exist}
      pid        -> {:ok, ref}
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
