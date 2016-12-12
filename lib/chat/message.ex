defmodule Message do
  require Logger
  def to_hash data do
    data |> String.split("\n")
         |> Enum.drop(-1)
         |> Enum.map(fn(x) -> split_strip(x) end)
         |> Enum.filter(fn(x) -> x != :empty end)
         |> Enum.into(%{})
  end

  def from_list tuples do
    tuples |> Enum.map(fn({k, v}) -> "#{String.upcase(k)}: #{v}" end)
           |> Enum.join("\n")
  end

  defp split_strip line do
    case String.split(line, ":") do
      [k, v] -> {k, String.lstrip(v)}
      [""]   -> :empty
    end
  end

  def handle :join, data, socket do
    Logger.info "have to handle join"
    %{"JOIN_CHATROOM" => room_name,
      "CLIENT_IP" => "0",
      "PORT" => "0",
      "CLIENT_NAME" => client_name} = to_hash(data)


    {:ok, join_id} = Chat.Rooms.add_member({client_name, socket}, room_name)
    {:ok, room_ref} = Chat.Rooms.get_ref(room_name)

    response = Message.from_list([
      {"JOINED_CHATROOM", room_name},
      {"SERVER_IP", @ip},
      {"PORT", "WHAT IS THE PORT"},
      {"ROOM_REF", "#{room_ref}"},
      {"JOIN_ID", "#{join_id}"},
    ])

    :gen_tcp.send(socket, response)
  end


  def handle :chat, data, socket do
    %{"CHAT" => room_ref,
      "JOIN_ID" => join_id,
      "CLIENT_" => client_name,
      "MESSAGE" => chat_message} = to_hash(data)

    Logger.info chat_message

  end

  def handle kind, data, _ do
    Logger.info "have to handle #{kind}"
  end


end
