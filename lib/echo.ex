defmodule Echo do
  require Logger


  @id   System.get_env("SK_STUDENTID")
  @ip   System.get_env("SK_IP_ADDRESS")
  @port Integer.parse(System.get_env("SK_PORTNUMBER")) |> elem(0)


  @tcp_options [
    :binary,          # recieve binaries
    packet: :line,    # line-by-line chunking
    active: false,    # blocks on :gen_tcp:recv/2 until we get data
    reuseaddr: true   # reuse address if listener has a crash
  ]

  @doc false
  def start(_type, _args) do
    import Supervisor.Spec

    Logger.debug "Using port #{@port} from config"

    children = [
      supervisor(Task.Supervisor, [[Name: Echo.TaskSupervisor]]),
      worker(Task, [Echo, :accept, [@port]]),
    ]

    opts = [strategy: :one_for_one, name: Echo.TaskSupervisor]


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
    serve client
    loop_acceptor socket
  end

  defp serve socket do
    read_line(socket)
    |> handle
    |> write_line(socket)
    serve socket
  end

  defp read_line socket do
    {:ok, data} = :gen_tcp.recv socket, 0
    data
  end

  defp write_line line, socket do
    :gen_tcp.send socket, line
  end


  defp handle "KILL_SERVICE\n" do
    Logger.info "Gotta die"
    System.halt(0)
  end

  defp handle "HELO " <> text do
    Logger.info "Got a HELO"
    ~s(HELO #{text}IP:#{@ip}\nPort:#{@port}\nStudentID:#{@id}\n)
  end

  defp handle data do
    Logger.info "Got unknown message: " <> data
    data
  end
end
