defmodule Chat.Server do
  use GenServer

  # API
  def start_link do
    GenServer.start_link(__MODULE__, [], name: :chat_room)
  end

  def add_message(message) do
    GenServer.cast(:chat_room, {:add_message, message})
  end

  def get_messages do
    GenServer.call(:chat_room, :get_messages)
  end

  # SERVER
  def init(messages) do
    {:ok, messages}
  end

  def handle_cast({:add_message, new_message}, messages) do
    {:noreply, [new_message |messages]}
  end

  def handle_call(:get_messages, _from, messages) do
    {:reply, messages, messages}
  end
end
