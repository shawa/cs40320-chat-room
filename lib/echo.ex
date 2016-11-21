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
    :ok = :gen_tcp.controlling_process client, pid
    loop_acceptor socket
  end

  defp serve socket do
      case :gen_tcp.recv(socket, 0) do
       {:ok, data} -> handle(data, socket)
                      serve socket

        _          -> Logger.info "client hung up"
                      {:error, :clientClosed}
       end
  end

  defp handle data, socket do
    write_line(data, socket)
  end

  defp write_line line, socket do
    :gen_tcp.send socket, line
  end
end
