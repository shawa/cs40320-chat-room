defmodule Chat.Rooms do
  require Logger
  use GenServer

  # API
  def start_link(name) do
    GenServer.start_link(__MODULE__, [], name: via_tuple(name))
  end

  def add_message(message, room_name) do
    GenServer.cast(via_tuple(room_name), {:add_message, message})
  end

  def add_member({name, socket}, room_name) do
    case Chat.Supervisor.get_room(room_name) do
      {:error, :does_not_exist} -> Chat.Supervisor.start_room(room_name)
      {:ok, pid}                -> :ok
    end

    GenServer.call(via_tuple(room_name), {:add_member, {name, socket}})
  end

  def drop_member({join_id, name}, room_name) do
    GenServer.cast(via_tuple(room_name), {:drop_member, {join_id, name}})
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
    state[:members] |> Enum.map(fn(x) -> elem(x, 2) |> :gen_tcp.send(message) end)
    {:noreply, state}
  end

  def handle_cast({:drop_member, {join_id, name}}, state) do
    Logger.info "Trying to drop #{name}, with id #{join_id}"

    new_members = Enum.filter(state[:members],
                              fn x -> !match?({join_id, name, _}, x) end)
    new_state = %{state | :members => new_memvers}

    {:noreply, new_members}
  end

  def handle_call({:add_member, new_member}, _from, state) do
    {name, socket} = new_member
    join_id    = :erlang.unique_integer
    new_member = {join_id, name, socket}
    
    new_state = %{state | :members => [new_member | state[:members]]}
    {:reply, {:ok, join_id}, new_state}
  end
end
