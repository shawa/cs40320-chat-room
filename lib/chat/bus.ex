defmodule Chat.Bus do
  use Supervisor
  require Logger

  @port 5000
  @ip "999.999.999.999"

  @tcp_options [
    :binary,        # recieve binaries
    packet: :raw,   # don't want line-by-line anymore
    active: false,  # blocks on :gen_tcp:recv/2 until we get data
    reuseaddr: true # reuse address if listener has a crash
  ]

  @doc false
  def init() do
    Logger.debug "Using port #{@port} from config"
    accept
  end

  def accept port \\ @port do
    case :gen_tcp.listen(port, @tcp_options) do
      {:ok, socket}         -> Logger.info "Accepting connections on port #{port}"
                               loop_acceptor socket
      {:error, :eacces}     -> exit "Can't bind to privileged port #{port}"
      {:error, :eaddrinuse} -> exit "Port #{port} in use"
    end
  end

  defp loop_acceptor socket do
    {:ok, client} = :gen_tcp.accept socket
    Logger.info "accepting new client socket"

    {:ok, pid} = Task.Supervisor.start_child(Chat.TaskSupervisor, fn -> serve(client) end)
    Logger.info "handed off to new child"

    case :gen_tcp.controlling_process client, pid do
      {:error, error} -> Logger.info error #TODO figure out this error
      :ok -> :ok
    end

    loop_acceptor socket
  end

  defp serve socket do
      case :gen_tcp.recv(socket, 0) do
       {:ok, data}       -> handle_message(data, socket)
                            serve socket
       {:error, :closed} -> Logger.info "client hung up"
                            :ok
       end
  end

  defp handle_message data, socket do
    action = case data do
        "JOIN_CHATROOM"  <> _ -> :join
        "LEAVE_CHATROOM" <> _ -> :leave
        "DISCONNECT"     <> _ -> :disconnect
        "CHAT"           <> _ -> :chat
                            _ -> :noidea
    end

    fields = Message.to_hash(data)
    handle(action, fields, socket)
  end

  defp handle :join, message, socket do
    Logger.info "have to handle join"

    %{"JOIN_CHATROOM" => room_name,
      "CLIENT_IP" => "0",
      "PORT" => "0",
      "CLIENT_NAME" => client_name} = message


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



  defp handle kind, data, _ do
    Logger.info "have to handle #{kind}"
  end

end
