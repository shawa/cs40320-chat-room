defmodule Chat.Rooms do
  require Logger
  use GenServer

  # API
  def start_link(name) do
    GenServer.start_link(__MODULE__, [], name: via_tuple(name))
  end

  def add_message(message, room_ref) do
    GenServer.cast(via_tuple(room_ref), {:add_message, message})
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
    GenServer.cast(via_tuple(room_ref), {:drop_member, {join_id, name}})
  end

  defp via_tuple(room_ref) do
    {:via, :gproc, {:n, :l, {:chat_room, room_ref}}}
  end

  # SERVER

  def init(_) do
    state = %{:members => []}
    {:ok, state}
  end

  def handle_cast({:add_message, message}, state) do
    Logger.info "Broadcasting message"
    IO.inspect(message)

    state[:members] |> Enum.map(fn(member) -> elem(member, 2) end)
                    |> Enum.map(fn(sock)   -> :gen_tcp.send(sock, message) end)

    {:noreply, state}
  end

  def handle_cast({:drop_member, {join_id, name}}, state) do
    Logger.info "Trying to drop #{name}, with id #{join_id}"
    IO.inspect state

    new_members = state[:members] |> Enum.filter(fn x -> !match?({join_id, name, _}, x) end)
    new_state = %{state | :members => new_members}
    
    IO.inspect state
    {:noreply, new_state}
  end

  def handle_call({:add_member, new_member}, _from, state) do
    {name, socket} = new_member
    join_id    = :erlang.unique_integer([:positive])
    new_member = {join_id, name, socket}
    new_state = %{state | :members => [new_member | state[:members]]}
    {:reply, {:ok, join_id}, new_state}
  end
end
