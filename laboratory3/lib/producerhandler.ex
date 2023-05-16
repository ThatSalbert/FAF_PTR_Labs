defmodule ProducerHandler do
  require Logger

  def handle_stuff(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        Logger.info("Producer received: #{data}")
        send_to_consumer(data)
        handle_stuff(socket)
      {:error, :closed} ->
        Logger.info("Producer closed")
      {:error, reason} ->
        Logger.info("Producer error: #{reason}")
    end
  end

  defp send_to_consumer(data) do
    {:ok, socket} = :gen_tcp.connect('localhost', 8001, [:binary, packet: :line, active: false])
    :gen_tcp.send(socket, data)
  end
end
