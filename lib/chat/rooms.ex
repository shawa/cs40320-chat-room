defmodule Chat.Rooms do
  require Logger
  use GenServer

  # API
  def start_link(name) do
    GenServer.start_link(__MODULE__, [], name: via_tuple(name))
  end

  def add_message(message, room_ref) do
    Logger.debug "called add_message"
    IO.inspect message
    GenServer.call(via_tuple(room_ref), {:add_message, message})
  end

  def add_member({name, socket}, room_name) do
    {:ok, ref} = case Chat.Supervisor.get_room(room_name) do
    {:error, :does_not_exist} -> Logger.info "can't find #{room_name}, starting"
                                 Chat.Supervisor.start_room(room_name)
    {:ok, ref}                -> {:ok, ref}
    end

    GenServer.call(via_tuple(ref), {:add_member, {name, socket}})
  end

  def drop_member({join_id, name}, room_ref) do
    res = GenServer.call(via_tuple(room_ref), {:drop_member, {join_id, name}})
    Logger.debug "dropped"
    res
  end

  defp via_tuple(room_ref) do
    {:via, :gproc, {:n, :l, {:chat_room, room_ref}}}
  end

  # SERVER

  def init(_) do
    members = []
    {:ok, members}
  end

  def handle_call({:add_message, message}, _from, members) do
    Logger.debug "Broadcasting message"
    IO.inspect(message)
    members |> Enum.map(fn(member) -> elem(member, 2) end)
            |> Enum.map(fn(sock)   -> :gen_tcp.send(sock, message) end)

    Logger.debug "sent to all"
    {:reply, {:ok}, members}
  end

  def handle_call({:drop_member, {join_id, name}}, _from, members) do
    Logger.info "Trying to drop #{name}, with id #{join_id}"
    IO.inspect join_id
    IO.inspect members
    new_members = Enum.reject members, fn(x) -> {i, n, _p} = x
                                                {i, n} == {join_id, name} end
    IO.inspect new_members
    {:reply, {:ok, join_id}, new_members}
  end

  def handle_call({:add_member, new_member}, _from, members) do
    {name, socket} = new_member
    if Enum.any?(members, fn({_i, n, _p}) -> n == name end) do
      new_members = members
    else
      join_id    = "#{:erlang.unique_integer([:positive])}"
      new_members = [{join_id, name, socket} | members]
    end
    {:reply, {:ok, join_id}, new_members}
  end
end
