defmodule Echo do
  require Logger


  @id   System.get_env("SK_STUDENTID")
  @ip   System.get_env("SK_IP_ADDRESS")
  @port Integer.parse(System.get_env("SK_PORTNUMBER")) |> elem(0)


  @tcp_options [
    :binary,        # recieve binaries
    packet: :raw,   # don't want line-by-line anymore
    active: false,  # blocks on :gen_tcp:recv/2 until we get data
    reuseaddr: true # reuse address if listener has a crash
  ]

  @doc false
  def start(_type, _args) do
    import Supervisor.Spec

    Logger.debug "Using port #{@port} from config"

    children = [
      supervisor(Task.Supervisor, [[name: Echo.TaskSupervisor]]),
      worker(Task, [Echo, :accept, [@port]]),

      # to be included in 1.4
      # http://elixir-lang.org/docs/master/elixir/Registry.html
      supervisor(Registry, [:duplicate, Echo.Rooms, [partitions: System.schedulers_online]])
    ]

    opts = [strategy: :one_for_one, name: Echo.Supervisor]
    Supervisor.start_link children, opts

  end

  def accept port do
    case :gen_tcp.listen(port, @tcp_options) do
      {:ok, socket} ->
        Logger.info "Accepting connections on port #{port}"
        loop_acceptor socket

      {:error, :eacces} ->
        exit "Yikes! Run as root to listen on privileged port #{port}"

      {:error, :eaddrinuse} ->
        exit "Looks like someone's already listening on port #{port}"
    end
  end

  defp loop_acceptor socket do
    {:ok, client} = :gen_tcp.accept socket
    {:ok, pid} = Task.Supervisor.start_child(Echo.TaskSupervisor, fn -> serve(client) end)

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
        "HELO "          <> _ -> :helo
        "KILL_SERVICE\n"      -> :guillotine
        "JOIN_CHATROOM"  <> _ -> :join
        "LEAVE_CHATROOM" <> _ -> :leave
        "DISCONNECT"     <> _ -> :disconnect
        "CHAT"           <> _ -> :chat
                            _ -> :noidea
    end
    handle(action, data, socket)
  end


  defp handle :join, data, socket do
    {room_name, _, _, client_name} = values(data)

    Logger.info("join from #{client_name} to #{room_name}")

    room_ref = ref room_name
    join_id = ref room_name, client_name

    {:ok, _} = Registry.register(Echo.Rooms, room_ref, {client_name, join_id, socket})

    """
    JOINED_CHATROOM:#{room_name}
    SERVER_IP: #{@ip}
    PORT:#{0}
    ROOM_REF:#{room_ref}
    JOIN_ID:#{join_id}
    """ |> write_to(socket)

    """
    CHAT:#{room_ref}
    CLIENT_NAME:#{client_name}
    MESSAGE:#{client_name} joined ##{room_name}\n\n
    """ |> post_to(room_ref)
  end

  defp handle :guillotine, _data, _socket do
    Logger.info "Killing service"
    System.halt(0)
  end

  defp handle :helo, data, socket do
    """
    #{data}IP:#{@ip}
    Port:#{@port}
    StudentID:#{@id}
    """ |> write_to(socket)
  end

  defp handle :leave, data, socket do
    {room_ref, join_id, client_name} = values(data)
    Logger.info("leave from #{client_name} of ${room_ref}, with join id #{join_id}")

    # TODO: remove a client from this list
    # take the client id and drop it from the keys()

    """
    LEFT_CHATROOM:#{room_ref}
    JOIN_ID:#{join_id}
    """ |> write_to(socket)
  end

  defp handle :disconnect, data, _socket do
    {0, 0, client_name} = values(data)
    Logger.info("disconnect from #{client_name}")
  end

  defp handle :chat, data, _socket do
    {room_ref, _join_id, client_name, message} = values(data)
    Logger.info("chat '#{message}' from #{client_name} in #{room_ref}")
    # send to all the clients in that room

    """
    CHAT:#{room_ref}
    CLIENT_NAME:#{client_name}
    MESSAGE:#{message}\n\n
    """ |> post_to(room_ref)
  end

  defp handle :noidea, data, _socket do
    Logger.info("well, I don't know what to do with this:\n#{data}")
  end

  defp values data do
    command = data
      |> String.split("\n")
      |> Enum.drop(-1)
      |> Enum.map(fn(x) -> String.split(x, ":")
                          |> tl
                          |> Enum.join("")
                          |> String.lstrip end)
      |> List.to_tuple
    Logger.info("Parsed this: #{Enum.join(Tuple.to_list(command))}")
    command
  end

  defp write_to data, socket do
    Logger.info("Sending this:")
    IO.inspect(data)

    :gen_tcp.send socket, data
  end

  defp post_to message, room_ref do
    Registry.dispatch(Echo.Rooms, room_ref, fn entries -> for {_, {_, _, sock}} <- entries, do: write_to(message, sock) end)

  end

  defp ref a do
    {refnumber, _} = :crypto.hash(:sha, a)
      |> Base.encode16
      |> Integer.parse(16)

    refnumber
  end

  defp ref a, b do
    ref a<>b
  end
end
