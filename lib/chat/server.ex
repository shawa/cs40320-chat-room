defmodule Chat.Server do
  require Logger
  use GenServer

  # API
  def start_link(name) do
    GenServer.start_link(__MODULE__, [], name: via_tuple(name))
  end

  def add_message(message, room_name) do
    GenServer.cast(via_tuple(room_name), {:add_message, message})
  end

  def add_member(client_name, room_name) do
    GenServer.call(via_tuple(room_name), {:add_member, client_name})
  end

  def get_members(room_name) do
    GenServer.call(via_tuple(room_name), :get_members)
  end

  def drop_member(client_name, room_name) do
    GenServer.cast(via_tuple(room_name), {:drop_member, client_name})
  end


  defp via_tuple(room_name) do
    {:via, :gproc, {:n, :l, {:chat_room, room_name}}}
  end

  # SERVER

  def init(state) do
    {:ok, state}
  end

  def handle_cast({:add_message, message}, state) do
    Logger.info "Broadcasting #{message}"
    {:noreply, state}
  end

  def handle_cast({:drop_member, member_to_drop}, members) do
    {:noreply, List.delete(members, member_to_drop)}
  end

  def handle_call({:add_member, new_member}, _from,  members) do
    join_id = :erlang.unique_integer
    {:reply, {:ok, join_id}, [new_member | members]}
  end

  def handle_call(:get_messages, _from, messages) do
    {:reply, messages, messages}
  end

  def handle_call(:get_members, _from, members) do
    {:reply, members, members}
  end

end
