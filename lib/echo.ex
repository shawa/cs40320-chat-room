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
        "JOIN_CHATROOM"  <> _ -> :join
        "LEAVE_CHATROOM" <> _ -> :leave
        "DISCONNECT"     <> _ -> :disconnect
        "CHAT"           <> _ -> :chat
                            _ -> :noidea
    end
    handle(action, data, socket)
  end


  defp handle :join, data, socket do
    {room_name, _, _, client_name, _} = values(data)
    Logger.info("join from #{client_name} to #{room_name}")

    # add the client to the room

    """
    JOINED_CHATROOM: #{room_name}
    SERVER_IP: #{@ip}
    PORT: #{0}
    ROOM_REF: <<ROOM_REF>>
    JOIN_ID: <<JOIN_ID>>
    """ |> write_line(socket)
  end

  defp handle :leave, data, socket do
    {room_ref, join_id, client_name} = values(data)
    Logger.info("leave from #{client_name} of ${room_ref}, with join id #{join_id}")

    """
    LEFT_CHATROOM: <<ROOM_REF>>
    JOIN_ID: <<integer previously provided by server on join>>
    """ |> write_line(socket)
  end

  defp handle :disconnect, data, socket do
    {0, 0, client_name} = values(data)
    Logger.info("disconnect from #{client_name}")
  end

  defp handle :chat, data, socket do
    {room_ref, join_id, client_name, message} = values(data)
    Logger.info("chat '#{message}' from #{client_name} in #{room_ref}")
    # send to all the clients in that room
  end

  defp handle :noidea, data, socket do
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
    Logger.info(Enum.join(Tuple.to_list(command)))
    command
  end

  defp write_line line, socket do
    :gen_tcp.send socket, line
  end
end