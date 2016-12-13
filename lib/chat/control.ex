defmodule Chat.Control do
  require Logger

  @port 5000
  @ip System.get_env("CHAT_IP_ADDRESS")
  @student_id System.get_env("STUDENT_NUMBER")

  def handle :kill_self, _data, _socket do
    Logger.info "Received halt, exiting."
    System.halt(0)
  end

  def handle :helo_reply, data, socket do
    Logger.info "Received HELO"
    response = """
    #{data}IP:#{@ip}
    Port:#{@port}
    StudentID:#{@student_id}
    """
    :gen_tcp.send(socket, response)
  end

  def handle :undefined_message, data, _socket do
    Logger.info "Received undefined command"
    IO.inspect(data)
  end
end
