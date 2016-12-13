defmodule Chat.Message do
  @port 5000
  @ip System.get_env("CHAT_IP_ADDRESS")

  require Logger
  def to_hash data do
    data |> String.split("\n")
         |> Enum.map(fn(x) -> split_strip(x) end)
         |> Enum.filter(fn(x) -> x != :empty end)
         |> Enum.into(%{})
  end

  def from_list tuples do
    IO.inspect tuples
    message = tuples |> Enum.map(fn({k, v}) -> "#{String.upcase(k)}:#{v}" end)
                     |> Enum.join("\n")

    response = message <> "\n"
    IO.inspect response
    response
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

    IO.inspect(data)

    {:ok, join_id} = Chat.Rooms.add_member({client_name, socket}, room_name)
    {:ok, room_ref} = Chat.Supervisor.get_room(room_name)

    response = from_list([
      {"JOINED_CHATROOM", room_name},
      {"SERVER_IP", @ip},
      {"PORT", "#{@port}"},
      {"ROOM_REF", "#{room_ref}"},
      {"JOIN_ID", "#{join_id}"},
    ])

    IO.inspect(response)

    :gen_tcp.send(socket, response)
  end


  def handle :chat, data, _socket do
    %{"CHAT" => room_ref,
      "CLIENT_NAME" => client_name,
      "JOIN_ID" => _join_id,
      "MESSAGE" => chat_message} = to_hash(data)

    room_message = from_list([
      {"CHAT", "#{room_ref}"},
      {"CLIENT_NAME", client_name},
      {"MESSAGE", "#{chat_message}\n\n"},
    ])

    Chat.Rooms.add_message(room_message, room_ref)
  end


  def handle :leave, data, socket do
    %{"LEAVE_CHATROOM" => room_ref,
      "JOIN_ID" => join_id,
      "CLIENT_NAME" => client_name} = to_hash(data)

    response = from_list([
      {"LEFT_CHATROOM", "#{room_ref}"},
      {"JOIN_ID", "#{join_id}"}
    ])
    :gen_tcp.send(socket, response)

    Chat.Rooms.drop_member({join_id, client_name}, room_ref)

    from_list([
      {"CHAT", "#{room_ref}"},
      {"CLIENT_NAME", client_name},
      {"MESSAGE", "#{client_name} has left the room\n\n"},
    ]) |> Chat.Rooms.add_message(room_ref)
  end

  def handle :disconnect, data, socket do
    %{"DISCONNECT" => "0",
      "PORT" => "0",
      "CLIENT_NAME" => _client_name} = to_hash(data)
    :gen_tcp.close(socket)
  end
end

