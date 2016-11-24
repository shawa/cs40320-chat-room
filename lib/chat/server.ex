defmodule Chat.Server do
  use GenServer

  # API
  def start_link(name) do
    GenServer.start_link(__MODULE__, [], name: via_tuple(name))
  end

  def add_message(room_name, message) do
    GenServer.cast(via_tuple(room_name), {:add_message, message})
  end

  def get_messages(room_name) do
    GenServer.call(via_tuple(room_name), :get_messages)
  end

  def add_member(client_name) do
    GenServer.cast(via_tuple(room_name), {:add_message, client_name})
  end

  def drop_member(client_name) do
    GenServer.cast(via_tuple(room_name), {:drop_member, client_name})
  end


  defp via_tuple(room_name) do
    {:via, Chat.Registry, {:chat_room, room_name}}
  end

  # SERVER

  def init(messages, members) do
    {:ok, messages, members}
  end

  def handle_cast({:add_message, new_message}, messages) do
    {:noreply, [new_message | messages]}
  end

  def handle_cast({:add_member, new_member}, members) do
    {:noreply, [new_member | members}
  end

  def handle_cast({:drop_member, member_to_drop}, members) do
    {:noreply, List.delete(members, member_to_drop)}
  end

  def handle_call(:get_messages, _from, messages) do
    {:reply, messages, messages}
  end

  def handle_call(:get_members, _from, members) do
    {:reply, members, members}
  end

end
