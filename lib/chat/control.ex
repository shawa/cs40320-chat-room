defmodule Chat.Control do
  require Logger

  def handle :kill_self, _data, _socket do
    Logger.info "Received halt, exiting."
    System.halt(0)
  end

  def handle :helo_reply, data, socket do
    Logger.info "Received HELO"
    response = """
    #{data}IP:192.168.1.1
    Port:WHATPORT IS IT
    StudentID:11110111
    """
    :gen_tcp.send(socket, response)
  end

  def handle :undefined_message, data, _socket do
    Logger.info "Received undefined command"
    IO.inspect(data)
  end
end
